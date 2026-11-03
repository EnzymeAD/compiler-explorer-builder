! Registering a function-like mathematical derivative rule via procedure pointer.
module function_like_mod
  implicit none
  private
  public :: wrapper

  procedure(approx_log1p), pointer, private :: &
    fn__enzyme_function_like__log1p => approx_log1p

contains

  double precision function approx_log1p(x) result(y)
    double precision, value :: x
    y = x - 0.5d0 * x * x
  end function approx_log1p

  double precision function wrapper(x) result(y)
    double precision, intent(in) :: x
    y = approx_log1p(x)
  end function wrapper

end module function_like_mod

program main
  use enzyme, only: enzyme_autodiff
  use function_like_mod, only: wrapper
  implicit none
  double precision :: x, dx

  x = 2.0d0
  dx = 0.0d0
  call enzyme_autodiff(wrapper, x, dx)

  write(*, '(a,f7.4)') 'wrapper(2.0)  =', wrapper(x)
  write(*, '(a,f7.4)') 'd/dx via rule =', dx
end program main
