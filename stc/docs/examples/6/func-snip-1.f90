  subroutine func(argc, argv, output)

    implicit none

    integer, intent(in) :: argc
    type (string_array) :: argv
    double precision, intent(out) :: output
