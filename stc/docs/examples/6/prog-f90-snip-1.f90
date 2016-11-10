argc = command_argument_count()
call string_array_create(argv, argc)

do i = 1, argc
   call get_command_argument(i, tmp)
   call string_array_set(argv, i, tmp)
end do
