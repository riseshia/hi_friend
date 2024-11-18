### update
class C
  def initialize(n)
    n
  end

  def foo(n)
    C
  end
end

C.new({1}).foo("str")

### hover
Integer
