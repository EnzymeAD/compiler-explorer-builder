double precision function square(x)
  implicit none
  double precision, intent(in) :: x
  square = x * x
end function square

double precision function dsquare(x)
  use enzyme, only: enzyme_autodiff
  implicit none
  double precision, external :: square
  double precision, intent(in) :: x
  double precision :: dx
  dx = 0.0d0
  ! Returns the derivative of square(x), i.e. 2 * x
  call enzyme_autodiff(square, x, dx)
  dsquare = dx
end function dsquare

program main
  implicit none
  double precision, external :: square, dsquare
  double precision :: x
  integer :: i
  do i = 1, 4
    x = dble(i)
    write(*, '(a,f3.1,a,f4.1,a,f3.1,a,f4.1)') &
      'square(', x, ')=', square(x), ', dsquare(', x, ')=', dsquare(x)
  end do
end program main
