! Reverse-mode gradient of a vector dot product using activity descriptors.
subroutine vec_dot(n, a, b, res)
  implicit none
  integer, intent(in) :: n
  double precision, dimension(n), intent(in) :: a, b
  double precision, intent(out) :: res
  integer :: i

  res = 0.0d0
  do i = 1, n
    res = res + a(i) * b(i)
  end do
end subroutine vec_dot

program main
  use enzyme, only: enzyme_autodiff, enzyme_const, enzyme_dup
  implicit none
  external :: vec_dot
  integer, parameter :: n = 4
  double precision, dimension(n) :: a, da, b, db
  double precision :: res, dres
  integer :: i

  a = [1.0d0, 2.0d0, 3.0d0, 4.0d0]
  b = [10.0d0, 20.0d0, 30.0d0, 40.0d0]
  da = 0.0d0
  db = 0.0d0
  dres = 1.0d0

  call enzyme_autodiff(vec_dot, enzyme_const, n, &
                       enzyme_dup, a, da, &
                       enzyme_dup, b, db, &
                       enzyme_dup, res, dres)

  write(*, '(a,f6.1)') 'dot(a, b) =', res
  do i = 1, n
    write(*, '(a,i1,a,f5.1,a,i1,a,f5.1)') &
      'd(dot)/da(', i, ') =', da(i), ', d(dot)/db(', i, ') =', db(i)
  end do
end program main
