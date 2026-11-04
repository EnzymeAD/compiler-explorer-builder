! Registering a function-like mathematical derivative rule via procedure pointer.
module function_like_mod
  implicit none
  private
  public :: wrapper

  procedure(approx_log1p), pointer, private :: &
    fn__enzyme_function_like__log1p => approx_log1p

contains

  function approx_log1p(x) result(y)
    real, value :: x
    real :: y
    y = x - 0.5 * x * x
  end function approx_log1p

  function wrapper(x) result(y)
    real, intent(in) :: x
    real :: y
    y = approx_log1p(x)
  end function wrapper

end module function_like_mod

program main
  use enzyme, only: enzyme_autodiff
  use function_like_mod, only: wrapper
  implicit none
  real :: x, dx

  x = 2.0
  dx = 0.0
  call enzyme_autodiff(wrapper, x, dx)

  write(*, '(a,f7.4)') 'wrapper(2.0)  =', wrapper(x)
  write(*, '(a,f7.4)') 'd/dx via rule =', dx
end program main
