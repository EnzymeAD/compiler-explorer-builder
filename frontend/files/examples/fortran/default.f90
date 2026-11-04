module square_mod
  use enzyme, only: enzyme_autodiff
  implicit none
  private
  public :: square, dsquare

contains

  real function square(x)
    real, intent(in) :: x
    square = x * x
  end function square

  real function dsquare(x)
    real, intent(in) :: x
    real :: dx
    dx = 0.0
    ! Returns the derivative of square(x), i.e. 2 * x
    call enzyme_autodiff(square, x, dx)
    dsquare = dx
  end function dsquare

end module square_mod

program main
  use square_mod, only: square, dsquare
  implicit none
  real :: x
  integer :: i

  do i = 1, 4
    x = real(i)
    write(*, '(2(a,f3.1,a,f4.1))') &
      'square(', x, ')=', square(x), ', dsquare(', x, ')=', dsquare(x)
  end do
end program main
