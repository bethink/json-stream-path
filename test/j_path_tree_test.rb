require 'json/stream'
require 'test/unit'

class JPathTreeTest < Test::Unit::TestCase

  def setup
    @tree = {
        one: {
            prev: nil,
            value: false,
            next: :two
        },
        two: {
            prev: :one,
            value: false,
            next: :three
        },
        three: {
            prev: :two,
            value: false,
            next: nil
        }
    }
  end

  def test_jpath_tree_creation
    jpath_tree = JPathTree.new('/one/two/three')
    assert_equal(@tree, jpath_tree.tree)
  end

  def test_empty_jpath
    jpath_tree = JPathTree.new('')
    assert_equal(nil, jpath_tree.tree)
  end

  def test_nil_jpath
    jpath_tree = JPathTree.new(nil)
    assert_equal(nil, jpath_tree.tree)
  end

  def test_invalid_jpath
    jpath_tree = JPathTree.new('invalid')
    assert_equal(nil, jpath_tree.tree)
  end

  def test_parse_feasibility_one
    jpath_tree = JPathTree.new('/one/two/three')
    return_ = jpath_tree.parsing_feasible?('one')
    expected_tree = @tree.clone
    expected_tree[:one][:value] = true
    assert_equal(expected_tree, jpath_tree.tree)
    assert_equal(nil, return_)

    return_ = jpath_tree.parsing_feasible?('three')
    assert_equal(expected_tree, jpath_tree.tree)
    assert_equal(nil, return_)

    return_ = jpath_tree.parsing_feasible?('two')
    expected_tree[:two][:value] = true
    assert_equal(expected_tree, jpath_tree.tree)
    assert_equal(nil, return_)

    return_ = jpath_tree.parsing_feasible?('three')
    expected_tree[:three][:value] = true
    assert_equal(expected_tree, jpath_tree.tree)
    assert_equal(true, return_)
  end

  def test_parse_feasibility_two
    jpath_tree = JPathTree.new('/one/two/three')
    return_ = jpath_tree.parsing_feasible?('two')
    assert_equal(@tree, jpath_tree.tree)
    assert_equal(nil, return_)
  end

  def test_parse_feasibility_three
    jpath_tree = JPathTree.new('/one/two/three')
    return_ = jpath_tree.parsing_feasible?('three')
    assert_equal(@tree, jpath_tree.tree)
    assert_equal(nil, return_)
  end

  def test_parse_feasibility_invalid
    jpath_tree = JPathTree.new('/one/two/three')
    return_ = jpath_tree.parsing_feasible?('four')
    assert_equal(@tree, jpath_tree.tree)
    assert_equal(nil, return_)
  end

  def test_parse_feasibility_nil
    jpath_tree = JPathTree.new('/one/two/three')
    return_ = jpath_tree.parsing_feasible?(nil)
    assert_equal(@tree, jpath_tree.tree)
    assert_equal(nil, return_)
  end

end