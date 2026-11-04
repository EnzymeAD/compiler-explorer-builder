! Reverse-mode gradient of a vector dot product using activity descriptors.
program main
  use enzyme, only: enzyme_autodiff, enzyme_const, enzyme_dup
  implicit none
  integer, parameter :: n = 4
  real, dimension(n) :: a, da, b, db
  real :: res, dres
  integer :: i

  a = [1.0, 2.0, 3.0, 4.0]
  b = [10.0, 20.0, 30.0, 40.0]
  da = 0.0
  db = 0.0
  dres = 1.0

  call enzyme_autodiff(vec_dot, enzyme_const, n, &
                       enzyme_dup, a, da, &
                       enzyme_dup, b, db, &
                       enzyme_dup, res, dres)

  write(*, '(a,f6.1)') 'dot(a, b) =', res
  do i = 1, n
    write(*, '(2(a,i1,a,f5.1))') &
      'd(dot)/da(', i, ') =', da(i), ', d(dot)/db(', i, ') =', db(i)
  end do

contains

  subroutine vec_dot(n, a, b, res)
    integer, intent(in) :: n
    real, dimension(n), intent(in) :: a, b
    real, intent(out) :: res
    integer :: i

    res = 0.0
    do i = 1, n
      res = res + a(i) * b(i)
    end do
  end subroutine vec_dot

end program main
