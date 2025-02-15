/*****************************************************************************/
/*  CLEARERR.C v8.1.3                                                        */
/*                                                                           */
/* Copyright (c) 1995-2017 Texas Instruments Incorporated                    */
/* http://www.ti.com/                                                        */
/*                                                                           */
/*  Redistribution and  use in source  and binary forms, with  or without    */
/*  modification,  are permitted provided  that the  following conditions    */
/*  are met:                                                                 */
/*                                                                           */
/*     Redistributions  of source  code must  retain the  above copyright    */
/*     notice, this list of conditions and the following disclaimer.         */
/*                                                                           */
/*     Redistributions in binary form  must reproduce the above copyright    */
/*     notice, this  list of conditions  and the following  disclaimer in    */
/*     the  documentation  and/or   other  materials  provided  with  the    */
/*     distribution.                                                         */
/*                                                                           */
/*     Neither the  name of Texas Instruments Incorporated  nor the names    */
/*     of its  contributors may  be used to  endorse or  promote products    */
/*     derived  from   this  software  without   specific  prior  written    */
/*     permission.                                                           */
/*                                                                           */
/*  THIS SOFTWARE  IS PROVIDED BY THE COPYRIGHT  HOLDERS AND CONTRIBUTORS    */
/*  "AS IS"  AND ANY  EXPRESS OR IMPLIED  WARRANTIES, INCLUDING,  BUT NOT    */
/*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR    */
/*  A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT    */
/*  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,    */
/*  SPECIAL,  EXEMPLARY,  OR CONSEQUENTIAL  DAMAGES  (INCLUDING, BUT  NOT    */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,    */
/*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY    */
/*  THEORY OF  LIABILITY, WHETHER IN CONTRACT, STRICT  LIABILITY, OR TORT    */
/*  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE    */
/*  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.     */
/*                                                                           */
/*****************************************************************************/
#include <stdio.h>
#include <_mutex.h>
#include <_data_synch.h>


/*****************************************************************************/
/* CLEARERR -  Clear the I/O error flag (_STATERR)                           */
/*                                                                           */
/*    This function calls a macro defined in stdio.h                         */
/*                                                                           */
/*****************************************************************************/
_CODE_ACCESS void clearerr(FILE *_fp) 
{ 
   /*------------------------------------------------------------------------*/
   /* For multi-threaded applications, the _clearerr() call must be in a     */
   /* critical section that guarantees single-threaded access to the file    */
   /* stream.                                                                */
   /*------------------------------------------------------------------------*/
   __TI_file_lock(_fp);

   _clearerr(_fp);

   /*------------------------------------------------------------------------*/
   /* Writeback local copy of the file stream to shared memory and           */
   /* invalidate the local copy so that next access will be read from shared */
   /* memory.                                                                */
   /*------------------------------------------------------------------------*/
   __TI_data_synch_WBINV(_fp, sizeof(FILE));
   __TI_file_unlock(_fp);
}

