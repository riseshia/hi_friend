## update: test.rbs
class Foo
  def foo: -> Foo
end

## update: test.rb
class Foo
  def initialize
    @foo = 1
  end

  attr_reader :foo
end

## diagnostics: test.rb
(6,2)-(6,18): expected: Foo; actual: Integer
