### update
class C
  def initialize(n)
    n
  end

  def foo(n)
    C
  end
end

def process(c)
  {c}.foo("str")
end

### hover
C
