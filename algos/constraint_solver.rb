# Constraint-based placement-enumeration solver.
#
# Every turn it enumerates all legal placements of every remaining ship, derives
# per-cell ship probabilities from them and fires at the most probable cell.
# Because the rules guarantee ships never touch (not even diagonally), hit
# clusters can be reasoned about logically:
#   - a placement may never touch a revealed ship cell it does not cover
#   - a hit cluster whose every legal covering placement is already fully hit IS
#     a sunk ship -> its whole neighborhood becomes known water and the ship is
#     removed from the remaining fleet (this solves the historical problem of
#     shooting around already-sunk ships)
#   - avengerAvailable flipping true is a free "helicarrier just sank" signal
# In the endgame (few placement combinations left) it switches from per-ship
# marginals to exact enumeration of all joint fleet configurations.
#
# The solver only reads API responses (grid/cell/result/avengerAvailable/
# avengerResult/finished) - it never touches mock internals.
require_relative '../helpers/algo_helpers.rb'
require_relative '../constants.rb'

module ConstraintSolver
  extend AlgoHelpers
  module_function

  GRID = Constants::GRID_SIZE
  CELLS = GRID * GRID
  FULL_MASK = (1 << CELLS) - 1
  # weight multiplier per covered open-hit cell in the ranking heuristic
  RANKING_BOOST = 50.0

  # --- tunables (module accessors so benchmarks can A/B them) -------------------
  class << self
    # switch to exact joint enumeration when the product of per-ship placement
    # counts drops below this
    attr_accessor :exact_enum_limit
    # :auto prefers ironman over thor when everything still hidden is at most
    # this size (hunting small ships is the expensive part of the endgame)
    attr_accessor :ironman_max_size
    # nil fires thor as soon as available; a float holds it until a real
    # hunting lull (no open cluster and best hit probability at or below this).
    # Benchmarks say: keep nil - early information compounds.
    attr_accessor :thor_hold_p
    # avenger strategy: :auto, or forced :hulk/:ironman/:thor/:none for benchmarks
    attr_accessor :avenger_strategy
    # expectimax lookahead for cluster probes (root expectimax, greedy rollouts)
    attr_accessor :lookahead

    def reset_tunables!
      self.exact_enum_limit = 30_000 # larger buys nothing measurable, only time
      self.ironman_max_size = 3
      self.thor_hold_p = nil
      self.avenger_strategy = :auto
      self.lookahead = true
    end
  end
  reset_tunables!

  def solve(api)
    Solver.new(api).run
  end

  # --- static placement tables ------------------------------------------------

  Placement = Struct.new(:cells, :cells_mask, :neighbor_mask)

  def cell_index(row, col) = row * GRID + col

  # 8-neighborhood mask of every cell, precomputed once
  NEIGHBOR_MASKS = Array.new(CELLS) do |idx|
    row, col = idx.divmod(GRID)
    mask = 0
    (-1..1).each do |dr|
      (-1..1).each do |dc|
        mask |= 1 << cell_index(row + dr, col + dc) if valid_coordinates?(row + dr, col + dc)
      end
    end
    mask
  end.freeze

  def neighbors_mask_of(cells)
    cells.reduce(0) { |mask, idx| mask | NEIGHBOR_MASKS[idx] }
  end

  def build_placement(cells)
    cells_mask = cells.reduce(0) { |m, idx| m | (1 << idx) }
    Placement.new(cells.freeze, cells_mask, neighbors_mask_of(cells) & ~cells_mask).freeze
  end

  def line_placements(size)
    placements = []
    GRID.times do |r|
      (GRID - size + 1).times do |c|
        placements << build_placement(size.times.map { |i| cell_index(r, c + i) })
      end
    end
    GRID.times do |c|
      (GRID - size + 1).times do |r|
        placements << build_placement(size.times.map { |i| cell_index(r + i, c) })
      end
    end
    placements
  end

  def heli_placements
    placements = []
    [Constants::IRREGULAR_SHIP_HORIZONTAL, Constants::IRREGULAR_SHIP_VERTICAL].each do |shape|
      (GRID - shape.length + 1).times do |r|
        (GRID - shape[0].length + 1).times do |c|
          cells = []
          shape.each_with_index do |shape_row, dr|
            shape_row.each_with_index do |cell, dc|
              cells << cell_index(r + dr, c + dc) if cell == 'I'
            end
          end
          placements << build_placement(cells)
        end
      end
    end
    placements
  end

  def popcount(mask) = mask.to_s(2).count('1')

  def mask_to_cells(mask)
    cells = []
    idx = 0
    while mask > 0
      cells << idx if mask.odd?
      mask >>= 1
      idx += 1
    end
    cells
  end

  # kind => [placements]; the two 3-ships share one entry with count 2
  PLACEMENTS = { heli: heli_placements }
               .merge(Constants::REGULAR_SHIPS.uniq.to_h { |size| [size, line_placements(size)] })
               .freeze

  INITIAL_FLEET = { heli: 1 }.merge(Constants::REGULAR_SHIPS.tally).freeze

  class ContradictionError < StandardError; end

  # --- the per-game solver ------------------------------------------------------

  class Solver
    include ConstraintSolver

    def initialize(api)
      @api = api
      @hit_mask = 0            # revealed ship cells (X)
      @miss_mask = 0           # revealed water (.)
      @deduced_water_mask = 0  # cells proven water by the no-touch rule
      @ironman_mask = 0        # known ship cells that are not revealed yet
      @sunk_mask = 0           # hit cells attributed to a deduced-sunk ship
      @remaining = INITIAL_FLEET.dup
      @avenger_ready = false
      @avenger_used = false
      @last_target = nil
      @last_avenger = nil
    end

    def run
      loop do
        deduce_sunk_ships
        probabilities = cell_probabilities

        response = next_move(probabilities)
        raise ContradictionError, "invalid move: #{response}" if response.key?('error') || response['result'] != true

        observe(response)
        return response['moveCount'] if response['finished']
      end
    end

    private

    # --- moves and observation --------------------------------------------------

    def next_move(probabilities)
      avenger = pick_avenger_move(probabilities) if @avenger_ready && !@avenger_used
      target = avenger ? avenger[:target] : best_target(probabilities)
      row, col = target.divmod(GRID)
      @last_target = target
      @last_avenger = avenger && avenger[:name]

      if avenger
        log { "avenger #{avenger[:name]} at #{row},#{col} (#{avenger[:reason]})" }
        @api.fire_with_avenger(row, col, avenger[:name])
      else
        log { "fire #{row},#{col} p=#{probabilities[target].round(3)}" }
        @api.fire(row, col)
      end
    end

    def observe(response)
      was_ready = @avenger_ready

      response['grid'].each_char.with_index do |char, idx|
        case char
        when 'X' then @hit_mask |= (1 << idx)
        when '.' then @miss_mask |= (1 << idx)
        end
      end
      @ironman_mask &= ~@hit_mask # revealed ironman hints are ordinary hits now

      @avenger_ready = response['avengerAvailable']
      @avenger_used = true if @last_avenger

      # avenger becoming available means the shot we just made sank the helicarrier
      mark_helicarrier_sunk if !was_ready && @avenger_ready

      process_avenger_result(response['avengerResult']) if @last_avenger
    end

    def mark_helicarrier_sunk
      fragment = fragment_containing(@last_target)
      raise ContradictionError, 'helicarrier flip without hit fragment' if fragment.zero?

      mark_sunk(fragment, :heli)
    end

    def process_avenger_result(result)
      case @last_avenger
      when 'hulk'
        cells = result.map { |point| cell_index(point['mapPoint']['x'], point['mapPoint']['y']) }
        unless cells.empty?
          mask = cells.reduce(0) { |m, idx| m | (1 << idx) }
          mark_sunk(mask, kind_for_size(cells.size))
        end
      when 'ironman'
        result.each do |point|
          idx = cell_index(point['mapPoint']['x'], point['mapPoint']['y'])
          @ironman_mask |= (1 << idx) if @hit_mask[idx].zero?
        end
      when 'thor'
        # thor's reveals are already part of the response grid
      end
    end

    def kind_for_size(size)
      return :heli if size == Constants::IRREGULAR_SHIP_SIZE

      @remaining.key?(size) ? size : nil
    end

    # --- knowledge masks ----------------------------------------------------------

    def water_mask = @miss_mask | @deduced_water_mask
    def evidence_mask = @hit_mask | @ironman_mask
    def open_evidence_mask = evidence_mask & ~@sunk_mask
    def candidate_mask = FULL_MASK & ~(@hit_mask | @miss_mask) & ~@deduced_water_mask

    def remaining_kinds = @remaining.select { |_, count| count.positive? }.keys

    def legal_placements(kind)
      water = water_mask
      conflict = evidence_mask
      heli_alive = kind == :heli

      PLACEMENTS[kind].select do |p|
        (p.cells_mask & water).zero? &&
          (p.cells_mask & @sunk_mask).zero? &&
          (p.neighbor_mask & conflict).zero? &&
          !(heli_alive && (p.cells_mask & ~@hit_mask).zero?)
      end
    end

    def all_legal_placements
      remaining_kinds.to_h { |kind| [kind, legal_placements(kind)] }
    end

    # --- deduction ------------------------------------------------------------------

    def fragments
      frags = []
      mask = open_evidence_mask
      until mask.zero?
        frag = grow_fragment(mask & -mask)
        frags << frag
        mask &= ~frag
      end
      frags
    end

    def grow_fragment(seed)
      allowed = open_evidence_mask
      frag = seed
      loop do
        grown = frag | (neighbors_mask_of(mask_to_cells(frag)) & allowed)
        return frag if grown == frag

        frag = grown
      end
    end

    def fragment_containing(idx)
      bit = 1 << idx
      (open_evidence_mask & bit).zero? ? 0 : grow_fragment(bit)
    end

    # a fragment whose every legal covering placement is fully hit is a sunk ship,
    # and its cells are exactly the fragment (ships of different clusters cannot
    # touch, so a fully hit covering placement cannot exceed its own cluster)
    def deduce_sunk_ships
      loop do
        placements = all_legal_placements.values.flatten(1)
        progressed = false

        fragments.each do |frag|
          covering = placements.select { |p| (p.cells_mask & frag) != 0 }
          raise ContradictionError, "fragment #{mask_to_cells(frag)} has no covering placement" if covering.empty?
          next unless covering.all? { |p| (p.cells_mask & ~@hit_mask).zero? }

          mark_sunk(frag, kind_for_size(popcount(frag)))
          progressed = true
          break # masks changed, recompute placements
        end

        return unless progressed
      end
    end

    def mark_sunk(fragment_mask, kind)
      if kind.nil? || @remaining.fetch(kind, 0) < 1
        raise ContradictionError, "sunk ship of impossible kind #{kind.inspect} (#{popcount(fragment_mask)} cells)"
      end

      @sunk_mask |= fragment_mask
      @deduced_water_mask |= neighbors_mask_of(mask_to_cells(fragment_mask)) & ~fragment_mask
      @remaining[kind] -= 1
      log { "deduced sunk #{kind} at #{mask_to_cells(fragment_mask).map { |i| i.divmod(GRID) }}" }
    end

    # --- probabilities ------------------------------------------------------------------

    # returns {cell_index => P(ship)}; also fills @target_scores (probe
    # ranking) and @fragment_hypotheses (lookahead)
    def cell_probabilities
      @target_scores = {}
      @fragment_hypotheses = {}
      placements_by_kind = all_legal_placements
      return {} if placements_by_kind.empty?

      exact_probabilities(placements_by_kind) || marginal_probabilities(placements_by_kind)
    end

    # Marginal model with fragment-aware mixtures. A hit cluster is exactly ONE
    # ship, so its cell probabilities are a mixture over the kinds that could
    # cover it - multiplying per-kind probabilities as if they were independent
    # ships badly overestimates cluster extensions (measured: shots "at 0.9"
    # were hitting 82% of the time before this).
    def marginal_probabilities(placements_by_kind)
      open_mask = open_evidence_mask
      candidates = candidate_mask
      frags = fragments
      miss_chance = Hash.new(1.0)

      free_by_kind = {}
      covering = frags.to_h { |frag| [frag, Hash.new { |h, k| h[k] = [] }] }
      placements_by_kind.each do |kind, placements|
        free_by_kind[kind] = []
        placements.each do |p|
          if (p.cells_mask & open_mask).zero?
            free_by_kind[kind] << p
          else
            frags.each { |frag| covering[frag][kind] << p if (p.cells_mask & frag) != 0 }
          end
        end
      end

      # each fragment is one unidentified ship: mix the candidate kinds
      fragment_load = Hash.new(0.0) # kind => expected number of ships tied up in fragments
      frags.each do |frag|
        cand = covering[frag]
        total_mass = cand.sum { |kind, ps| @remaining[kind] * ps.size }.to_f
        next if total_mass.zero? # deduce_sunk_ships would have raised; defensive

        cell_mass = Hash.new(0.0)
        hypothesis_priors = []
        hypothesis_masks = []
        cand.each do |kind, ps|
          prior = @remaining[kind].to_f
          fragment_load[kind] += prior * ps.size / total_mass
          ps.each do |p|
            hypothesis_priors << prior
            hypothesis_masks << p.cells_mask
            p.cells.each do |idx|
              cell_mass[idx] += prior if candidates[idx] == 1
            end
          end
        end
        @fragment_hypotheses[frag] = [hypothesis_priors, hypothesis_masks]
        cell_mass.each do |idx, mass|
          miss_chance[idx] *= 1.0 - [mass / total_mass, 1.0].min
        end
      end

      # hunting: ships not tied up in a fragment roam the free placements
      placements_by_kind.each_key do |kind|
        placements = free_by_kind[kind]
        next if placements.empty?

        effective_count = @remaining[kind] - fragment_load[kind]
        next if effective_count <= 0

        total = placements.size.to_f
        cell_count = Hash.new(0)
        placements.each do |p|
          p.cells.each { |idx| cell_count[idx] += 1 if candidates[idx] == 1 }
        end
        cell_count.each do |idx, count|
          miss_chance[idx] *= (1.0 - count / total)**effective_count
        end
      end

      probabilities = {}
      miss_chance.each { |idx, miss| probabilities[idx] = 1.0 - miss }
      @target_scores = ranking_scores(placements_by_kind, open_mask, candidates)
      # an ironman hint is a certain hit
      mask_to_cells(@ironman_mask & candidates).each do |idx|
        probabilities[idx] = 1.0
        @target_scores[idx] = 1.0
      end
      probabilities
    end

    # Shot ranking, deliberately separate from the honest probabilities: treat
    # every ship kind as if it independently committed to each open cluster
    # (per-kind placement shares, boosted by covered open hits, combined as a
    # product). This overweights cells that are near-certain for SOME candidate
    # kind, so probing them resolves the cluster's identity fast. It is badly
    # calibrated as a probability, but as a probe ORDER it consistently beats
    # ranking by the honest posterior (measured ~0.3 moves/game).
    def ranking_scores(placements_by_kind, open_mask, candidates)
      scores = Hash.new { |hash, idx| hash[idx] = 1.0 }
      placements_by_kind.each do |kind, placements|
        total_weight = 0.0
        cell_weight = Hash.new(0.0)
        placements.each do |p|
          weight = RANKING_BOOST**popcount(p.cells_mask & open_mask)
          total_weight += weight
          p.cells.each do |idx|
            cell_weight[idx] += weight if candidates[idx] == 1
          end
        end
        next if total_weight.zero?

        cell_weight.each do |idx, weight|
          scores[idx] *= (1.0 - [weight / total_weight, 1.0].min)**@remaining[kind]
        end
      end
      scores.transform_values { |miss| 1.0 - miss }
    end

    def exact_probabilities(placements_by_kind)
      ships = []
      placements_by_kind.each do |kind, placements|
        return nil if placements.empty? # contradiction, let marginal path handle visibility

        @remaining[kind].times { ships << [kind, placements] }
      end
      return nil if ships.empty?

      combinations = ships.reduce(1) { |product, (_, placements)| product * placements.size }
      return nil if combinations > ConstraintSolver.exact_enum_limit

      # keep identical kinds adjacent (duplicate elimination relies on it)
      ships.sort_by! { |kind, placements| [placements.size, kind.to_s] }
      union_after = Array.new(ships.size + 1, 0)
      (ships.size - 1).downto(0) do |i|
        union_after[i] = union_after[i + 1] | ships[i][1].reduce(0) { |m, p| m | p.cells_mask }
      end

      @exact_total = 0
      @exact_cell_counts = Hash.new(0)
      @dup_start_stack = Array.new(ships.size, 0)
      enumerate_configs(ships, 0, 0, 0, [], open_evidence_mask, union_after)
      return nil if @exact_total.zero? # only possible on inconsistent state; be defensive

      candidates = candidate_mask
      probabilities = {}
      @exact_cell_counts.each do |idx, count|
        probabilities[idx] = count.to_f / @exact_total if candidates[idx] == 1
      end
      probabilities
    end

    def enumerate_configs(ships, level, used_mask, covered_mask, chosen, open_mask, union_after)
      if level == ships.size
        return unless (open_mask & ~covered_mask).zero?

        @exact_total += 1
        chosen.each do |p|
          p.cells.each { |idx| @exact_cell_counts[idx] += 1 }
        end
        return
      end

      kind, placements = ships[level]
      # identical ships: enforce ascending placement order to avoid double counting
      start = level.positive? && ships[level - 1][0] == kind ? @dup_start_stack[level - 1] + 1 : 0

      placements.each_with_index do |p, i|
        next if i < start
        next unless (p.cells_mask & used_mask).zero?
        # every open hit cell must remain coverable by the ships still to be placed
        next unless ((open_mask & ~(covered_mask | p.cells_mask)) & ~union_after[level + 1]).zero?

        @dup_start_stack[level] = i
        chosen.push(p)
        enumerate_configs(ships, level + 1, used_mask | p.cells_mask | p.neighbor_mask,
                          covered_mask | p.cells_mask, chosen, open_mask, union_after)
        chosen.pop
      end
    end

    # --- targeting -----------------------------------------------------------------------

    # marginal turns rank by the identity-resolving heuristic (optionally
    # improved by expectimax lookahead), exact turns by the true posterior
    def best_target(probabilities)
      raise ContradictionError, 'no target available' if probabilities.empty?

      if ConstraintSolver.lookahead && !@fragment_hypotheses.empty?
        improved = lookahead_target
        return improved if improved
      end
      return @target_scores.max_by { |_, score| score }[0] unless @target_scores.empty?

      probabilities.max_by { |_, probability| probability }[0]
    end

    LOOKAHEAD_MAX_HYPOTHESES = 120
    LOOKAHEAD_ROOT_CANDIDATES = 10

    # Root expectimax over a cluster's hypothesis set (each hypothesis = one
    # possible (kind, placement) of the cluster's ship), with greedy rollouts
    # below the root: pick the probe minimizing the expected number of MISSES
    # needed to fully resolve the cluster. Probing the highest-probability cell
    # is not always that probe - sometimes a cheaper cell splits the hypothesis
    # space so the follow-ups become certain.
    def lookahead_target
      best_cell = nil
      best_gain = 1e-6

      @fragment_hypotheses.each_value do |priors, masks|
        next if masks.size < 2 || masks.size > LOOKAHEAD_MAX_HYPOTHESES

        @rollout_priors = priors
        @rollout_masks = masks
        @rollout_candidates = candidate_mask
        @rollout_memo = {}
        all_alive = (1 << masks.size) - 1
        base_cost = rollout_cost(all_alive, 0)

        union = masks.reduce(0, :|) & @rollout_candidates
        total_mass = priors.sum
        cells = mask_to_cells(union)
        top = cells.sort_by { |u| -hypothesis_mass(all_alive, u) }.first(LOOKAHEAD_ROOT_CANDIDATES)

        top.each do |u|
          bit = 1 << u
          hit_alive, miss_alive = split_alive(all_alive, bit)
          hit_probability = hypothesis_mass(all_alive, u) / total_mass
          value = 0.0
          value += hit_probability * rollout_cost(hit_alive, bit) unless hit_alive.zero?
          value += (1.0 - hit_probability) * (1.0 + rollout_cost(miss_alive, bit)) unless miss_alive.zero?
          gain = base_cost - value
          if gain > best_gain
            best_gain = gain
            best_cell = u
          end
        end
      end

      best_cell
    end

    def hypothesis_mass(alive, cell)
      bit = 1 << cell
      mass = 0.0
      each_alive(alive) { |id| mass += @rollout_priors[id] if (@rollout_masks[id] & bit) != 0 }
      mass
    end

    def each_alive(alive)
      id = 0
      while alive > 0
        yield id if alive.odd?
        alive >>= 1
        id += 1
      end
    end

    def split_alive(alive, bit)
      hit_alive = 0
      miss_alive = 0
      each_alive(alive) do |id|
        if (@rollout_masks[id] & bit).zero?
          miss_alive |= 1 << id
        else
          hit_alive |= 1 << id
        end
      end
      [hit_alive, miss_alive]
    end

    # expected misses to fully resolve the cluster, following greedy max-mass
    # probing on the surviving hypotheses
    def rollout_cost(alive, probed_mask)
      return 0.0 if alive.zero? || (alive & (alive - 1)).zero? # <= 1 hypothesis: only sure hits remain

      key = [alive, probed_mask]
      cached = @rollout_memo[key]
      return cached if cached

      union = 0
      total_mass = 0.0
      each_alive(alive) do |id|
        union |= @rollout_masks[id]
        total_mass += @rollout_priors[id]
      end

      best_cell = nil
      best_mass = -1.0
      mask_to_cells(union & @rollout_candidates & ~probed_mask).each do |u|
        mass = hypothesis_mass(alive, u)
        if mass > best_mass
          best_mass = mass
          best_cell = u
        end
      end
      return @rollout_memo[key] = 0.0 if best_cell.nil?

      bit = 1 << best_cell
      hit_alive, miss_alive = split_alive(alive, bit)
      hit_probability = best_mass / total_mass
      cost = 0.0
      cost += hit_probability * rollout_cost(hit_alive, probed_mask | bit) unless hit_alive.zero?
      cost += (1.0 - hit_probability) * (1.0 + rollout_cost(miss_alive, probed_mask | bit)) unless miss_alive.zero?
      @rollout_memo[key] = cost
    end

    def pick_avenger_move(probabilities)
      return nil if probabilities.empty?

      case ConstraintSolver.avenger_strategy
      when :none then nil
      when :hulk then { name: 'hulk', target: best_target(probabilities), reason: 'forced strategy' }
      when :ironman then { name: 'ironman', target: best_target(probabilities), reason: 'forced strategy' }
      when :thor then { name: 'thor', target: best_target(probabilities), reason: 'forced strategy' }
      else auto_avenger_move(probabilities)
      end
    end

    # Thor's 10 free reveals (hits anchor ships, water prunes placements) beat
    # hulk's E[size-1] saving; ironman's guaranteed anchor wins only when
    # everything still hidden is small (hunting smalls costs the most).
    def auto_avenger_move(probabilities)
      hidden_smalls_only = open_evidence_mask.zero? && remaining_kinds.all? do |kind|
        (kind == :heli ? Constants::IRREGULAR_SHIP_SIZE : kind) <= ConstraintSolver.ironman_max_size
      end

      if hidden_smalls_only && @ironman_mask.zero?
        return { name: 'ironman', target: best_target(probabilities), reason: 'only hidden small ships left' }
      end

      hold = ConstraintSolver.thor_hold_p
      if hold && !(open_evidence_mask.zero? && probabilities.values.max <= hold)
        return nil # keep holding until a real hunting lull
      end

      { name: 'thor', target: best_target(probabilities), reason: 'free reveals' }
    end

    def log(&block)
      puts "[solver] #{block.call}" if AlgoHelpers.verbose
    end
  end
end
