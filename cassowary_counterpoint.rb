require 'cassowary'

# http://strasheela.sourceforge.net/strasheela/doc/Example-FuxianFirstSpeciesCounterpoint.html
#
# A few rules restrict the melodic aspect of the counterpoint writing. Only melodic intervals up to a fourth, a fifth, and an octave are allowed. No note repetition is permitted. All notes must be diatonic pitches (i.e. there can be no augmented, diminished, or chromatic melodic intervals). The counterpoint remains in a narrow pitch range. Melodic steps are preferred (this rule is so elementary that the Fux' first chapter does not even mention it).
#
# Furthermore, some rules restrict the relation between both voices. Open and hidden parallels are forbidden, that is, direct motion into a perfect consonance is not allowed. Only consonances are permitted as intervals between simultaneous notes and there should be more imperfect than perfect consonances. The first and last notes, however, must form a perfect consonance. Finally, the counterpoint must be in the same mode as the cantus firmus.
#
#
class Counterpointer
  include Cassowary

  PERFECT_CONSONANT   = [0, 5, 7]
  CONSONANT           = [0, 3, 4, 5, 7, 8, 9]
  IMPERFECT_CONSONANT = [3, 4, 8, 9]
  RANGE               = -10..10

  def self.run
    x = Variable.new(name: 'x')
    solver = SimplexSolver.new
    cantus_firmus = [nil, 0, 2, 1, 0, 3, 2, 4, 3, 2, 1, 0]

    note_pairs = cantus_firmus.each_cons(2).to_a
    counterpoint_notes = []

    # constraints about counterpoint notes
    solver.add_bounds x, RANGE.first, RANGE.last

    note_pairs.each.with_index do |(prev_note, curr_note), idx|
      if idx != 0
        last_interval = (counterpoint_notes[idx - 1] - prev_note).to_i
      end

      # counterpoint stays below the melody
      #solver.add_constraint x.cn_leq(curr_note)

      # counterpoint stays above the melody
      #solver.add_constraint curr_note.cn_leq(x)

      # start with perfect consonant
      # finish with perfect consonant
      if idx == 0 or idx == note_pairs.length
        pc_constraints = PERFECT_CONSONANT.map {|pc|
          x.cn_equal(curr_note - pc, Strength::StrongStrength)
        }
        pc_constraints.each do |pc_constraint|
          solver.add_constraint pc_constraint
        end
      else
        # anything else is imperfect consonant
        # but filter out parallel PERFECT intervals
        #
        # TODO: fix so as to only filter parallel perfect intervals
        #
        #
        ic_constraints = IMPERFECT_CONSONANT.select {|ic| ic != last_interval }.map {|ic|
          x.cn_equal(curr_note - ic, Strength::StrongStrength)
        }
        ic_constraints.each do |ic_constraint|
          solver.add_constraint ic_constraint
        end
      end

      # restrict stepwise movt to less than 3 for the counterpoint
      if idx != 0
        step_limit_constraint = (x + curr_note).cn_leq(counterpoint_notes[idx - 1] + 5)
        solver.add_constraint step_limit_constraint
      end

      # solve it!
      counterpoint_notes << (curr_note + x.value)

      # reset constraints
      if step_limit_constraint
        solver.remove_constraint step_limit_constraint
      end

      Array(pc_constraints).each do |pc_constraint|
        solver.remove_constraint pc_constraint
      end

      Array(ic_constraints).each do |ic_constraint|
        solver.remove_constraint ic_constraint
      end
    end

    puts counterpoint_notes.map(&:to_i).inspect
  end
end

Counterpointer.run
