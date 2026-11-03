! Forward-mode directional derivative using enzyme_fwddiff.
subroutine l2_norm_sq(n, x, y)
  implicit none
  integer, intent(in) :: n
  double precision, dimension(n), intent(in) :: x
  double precision, intent(out) :: y
  integer :: i

  y = 0.0d0
  do i = 1, n
    y = y + x(i) * x(i)
  end do
end subroutine l2_norm_sq

program main
  use enzyme, only: enzyme_fwddiff, enzyme_const, enzyme_dup
  implicit none
  external :: l2_norm_sq
  integer, parameter :: n = 3
  double precision, dimension(n) :: x, dx
  double precision :: y, dy

  x  = [2.0d0, 3.0d0, 6.0d0]
  dx = [1.0d0, 0.5d0, -1.0d0]

  call enzyme_fwddiff(l2_norm_sq, enzyme_const, n, &
                      enzyme_dup, x, dx, &
                      enzyme_dup, y, dy)

  write(*, '(a,f6.2)') 'y  = ||x||^2      =', y
  write(*, '(a,f6.2)') 'dy = grad(y) . dx =', dy
end program main
