! Custom reverse-mode derivative registration in pure Fortran.
module custom_rule_mod
  implicit none
  private
  public :: evaluate

  type :: gradient_registration
    procedure(scaled_op), pointer, nopass :: primal => scaled_op
    procedure(augment_scaled_op), pointer, nopass :: augmented => augment_scaled_op
    procedure(reverse_scaled_op), pointer, nopass :: reverse => reverse_scaled_op
  end type gradient_registration

  ! Enzyme reads this static initializer at compile time to register the custom rule.
  type(gradient_registration) :: f__enzyme_register_gradient_scaled_op

contains

  subroutine scaled_op(x, y)
    double precision, intent(in) :: x
    double precision, intent(out) :: y
    y = 2.0d0 * x
  end subroutine scaled_op

  subroutine augment_scaled_op(x, dx, y, dy)
    double precision, intent(in) :: x, dx
    double precision, intent(out) :: y
    double precision, intent(inout) :: dy
    call scaled_op(x, y)
  end subroutine augment_scaled_op

  subroutine reverse_scaled_op(x, dx, y, dy)
    double precision, intent(in) :: x, y
    double precision, intent(inout) :: dx, dy
    ! Custom rule: supply d/dx log(1 + x) = 1 / (1 + x)
    dx = dx + dy / (1.0d0 + x)
    dy = 0.0d0
  end subroutine reverse_scaled_op

  double precision function evaluate(x) result(y)
    double precision, intent(in) :: x
    call scaled_op(x, y)
  end function evaluate

end module custom_rule_mod

program main
  use enzyme, only: enzyme_autodiff
  use custom_rule_mod, only: evaluate
  implicit none
  double precision :: x, dx, y

  x = 2.0d0
  dx = 0.0d0
  y = evaluate(x)
  call enzyme_autodiff(evaluate, x, dx)

  write(*, '(a,f6.4)') 'y  = ', y
  write(*, '(a,f6.4)') 'dx = ', dx
end program main
