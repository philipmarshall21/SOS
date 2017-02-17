      program complex_reductions_f
      implicit none
      include "shmem.fh"
      
      integer psync(shmem_reduce_sync_size), i, j, nr
      data psync /shmem_reduce_sync_size*shmem_sync_value/
      parameter (nr=10)
      complex z_src(nr), z_target(nr)
      complex pwrk(max(nr/2+1,shmem_reduce_min_wrkdata_size))
      double complex zd_src(nr), zd_target(nr)
      double complex pwrkd(max(nr/2+1,shmem_reduce_min_wrkdata_size))
      common /com/ z_src, z_target, pwrk
      common /com/ zd_src, zd_target, pwrkd
      integer shmem_my_pe, shmem_n_pes, npes, me
      complex exp_result(nr)
      double complex exp_result_d(nr)
      
      
      call shmem_init()
      
      npes = shmem_n_pes()
      me = shmem_my_pe()

      ! Set up the source buffer and calculate the expected sum reduction result:
      do i=1,nr
        z_src(i) = complex(me,me+1)
        exp_result(i) = z_src(i)
        do j=0,npes-1
          if (j .ne. me) then
            exp_result(i) = exp_result(i) + complex(j,j+1)
          end if
        end do
      end do

      ! Test single precision complex sum_to_all reductions:
      call shmem_comp4_sum_to_all(z_target, z_src, nr, 0, 0, npes, pwrk, psync)

      ! Check the result:
      call check_result_complex(z_target, z_src, exp_result, nr, 1)

      call shmem_barrier_all()

      ! Test single precision complex sum reduction on a PE subset with a stride of 2
      if ( mod(me,2) .eq. 0) then
        if ( mod(shmem_n_pes(),2) .eq. 0) then

          call shmem_comp4_sum_to_all(z_target, z_src, nr, 0, 1, npes/2, pwrk, psync)

          do i=1,nr
            exp_result(i) = z_src(i)
            do j=0,npes-1,2
              if (j .ne. me) then
                exp_result(i) = exp_result(i) + complex(j,j+1)
              end if
            end do
          end do

          call check_result_complex(z_target, z_src, exp_result, nr, 2)

        endif
      endif

      call shmem_barrier_all()

      ! Initialize the double precision buffers and expected result
      do i=1,nr
        zd_src(i) = dcmplx(-7.123123123123123123123, 2.32132132132132132132)
        exp_result_d(i) = zd_src(i)*npes
      end do 

      ! Test double precision complex sum_to_all reductions:
      call shmem_comp8_sum_to_all(zd_target, zd_src, nr, 0, 0, npes, pwrkd, psync)
      
      call check_result_complex_dbl(zd_target, zd_src, exp_result_d, nr, 3)

      call shmem_barrier_all()
      
      ! Test double precision sum reductions on a PE subset with a stride of 2
      if ( mod(me,2) .eq. 0) then
        if ( mod(shmem_n_pes(),2) .eq. 0) then

          call shmem_comp8_sum_to_all(zd_target, zd_src, nr, 0, 1, npes/2, pwrkd, psync)

          do i=1,nr
            exp_result_d(i) = zd_src(i)*(npes/2)
          end do

          call check_result_complex_dbl(zd_target, zd_src, exp_result_d, nr, 4)

        endif
      endif

      call shmem_barrier_all()

      ! Re-initialize the source and expected result buffers for single precision
      do i=1,nr
        z_src(i) = complex(me,me+1)
        exp_result(i) = z_src(i)
        do j=0,npes-1
          if (j .ne. me) then
            exp_result(i) = exp_result(i) * complex(j,j+1)
          end if
        end do
      end do

      ! Test single precision complex product_to_all reductions:
      call shmem_comp4_prod_to_all(z_target, z_src, nr, 0, 0, npes, pwrk, psync)

      ! Check the result:
      call check_result_complex(z_target, z_src, exp_result, nr, 5)
      
      call shmem_barrier_all()
      
      ! Test single precision product reduction on a PE subset with a stride of 2
      if ( mod(me,2) .eq. 0) then
        if ( mod(shmem_n_pes(),2) .eq. 0) then

          call shmem_comp4_prod_to_all(z_target, z_src, nr, 0, 1, npes/2, pwrk, psync)

          do i=1,nr
            exp_result(i) = z_src(i)
            do j=0,npes-1,2
              if (j .ne. me) then
                exp_result(i) = exp_result(i) * complex(j,j+1)
              end if
            end do
          end do

          call check_result_complex(z_target, z_src, exp_result, nr, 6)

        endif
      endif
      
      call shmem_barrier_all()
      
      ! Re-initialize the double precision buffers and expected result
      do i=1,nr
        zd_src(i) = dcmplx(me, me+1)
        exp_result_d(i) = zd_src(i)
        do j=0,npes-1
          if (j .ne. me) then
            exp_result_d(i) = exp_result_d(i) * dcmplx(j,j+1)
          end if
        end do
      end do 

      ! Test double precision complex product_to_all reductions:
      call shmem_comp8_prod_to_all(zd_target, zd_src, nr, 0, 0, npes, pwrkd, psync)
      
      call check_result_complex_dbl(zd_target, zd_src, exp_result_d, nr, 7)

      call shmem_barrier_all()
      
      ! Test double precision product reduction on a PE subset with a stride of 2
      if ( mod(me,2) .eq. 0) then
        if ( mod(shmem_n_pes(),2) .eq. 0) then

          call shmem_comp8_prod_to_all(zd_target, zd_src, nr, 0, 1, npes/2, pwrkd, psync)

          do i=1,nr
            exp_result_d(i) = zd_src(i)
            do j=0,npes-1,2
              if (j .ne. me) then
                exp_result_d(i) = exp_result_d(i) * dcmplx(j,j+1)
              end if
            end do
          end do

          call check_result_complex_dbl(zd_target, zd_src, exp_result_d, nr, 8)

        endif
      endif
      
      call shmem_finalize()

      contains

      subroutine check_result_complex(z_target, z_src, correct, N, id)
        implicit none
        integer N, id, me
        complex z_target(N), z_src(N), correct(N)

        me = shmem_my_pe()
        do i=1,N
          if (z_target(i) .ne. exp_result(i)) then
            print *, "fail : have ", z_target(i), " expected ", &
                     exp_result(i), " on process ", me, " test #", id
            call shmem_global_exit(id)
          endif
        end do
      end subroutine check_result_complex

      subroutine check_result_complex_dbl(zd_target, zd_src, correct, N, id)
        implicit none
        integer N, id, me
        double complex zd_target(N), zd_src(N), correct(N)
        double precision e

        me = shmem_my_pe()
        do i=1,N
        if ( (realpart(zd_target(i)) - realpart(exp_result_d(i))) .gt. epsilon(e) ) then
          print *, "fail : incorrect real component ", realpart(zd_target(i)), &
            " expected ", realpart(exp_result_d(i)), " on process ", me, "test #", id
          call shmem_global_exit(id)
        endif
        if ( (imagpart(zd_target(i)) - imagpart(exp_result_d(i))) .gt. epsilon(e) ) then
          print *, "fail : incorrect imaginary component ", imagpart(zd_target(i)), &
            " expected ", imagpart(exp_result_d(i)), " on process ", me, "test #", id
          call shmem_global_exit(id)
        endif
        end do
      end subroutine check_result_complex_dbl
      
      end program complex_reductions_f
