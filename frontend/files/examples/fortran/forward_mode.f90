! Forward-mode directional derivative using enzyme_fwddiff.
program main
  use enzyme, only: enzyme_fwddiff, enzyme_const, enzyme_dup
  implicit none
  integer, parameter :: n = 3
  real, dimension(n) :: x, dx
  real :: y, dy

  x  = [2.0, 3.0, 6.0]
  dx = [1.0, 0.5, -1.0]

  call enzyme_fwddiff(l2_norm_sq, enzyme_const, n, &
                      enzyme_dup, x, dx, &
                      enzyme_dup, y, dy)

  write(*, '(a,f6.2)') 'y  = ||x||^2      =', y
  write(*, '(a,f6.2)') 'dy = grad(y) . dx =', dy

contains

  subroutine l2_norm_sq(n, x, y)
    integer, intent(in) :: n
    real, dimension(n), intent(in) :: x
    real, intent(out) :: y
    integer :: i

    y = 0.0
    do i = 1, n
      y = y + x(i) * x(i)
    end do
  end subroutine l2_norm_sq

end program main
