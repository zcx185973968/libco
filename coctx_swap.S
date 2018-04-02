/*
* Tencent is pleased to support the open source community by making Libco available.

* Copyright (C) 2014 THL A29 Limited, a Tencent company. All rights reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License"); 
* you may not use this file except in compliance with the License. 
* You may obtain a copy of the License at
*
*	http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, 
* software distributed under the License is distributed on an "AS IS" BASIS, 
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
* See the License for the specific language governing permissions and 
* limitations under the License.
*/

.globl coctx_swap
#if !defined( __APPLE__ ) && !defined( __FreeBSD__ )
.type  coctx_swap, @function
#endif
coctx_swap:

#if defined(__i386__)
	//此时上一个函数的压栈已经完成了，当前栈结构是  sp->返回地址  sp+4->参数1的地址,也就是当前协程 sp+8参数2的地址，也就是目标协程
	//因为x86的push esp,mov ebp=esp是加在下一个函数里的，所以此处还没有执行。
	leal 4(%esp), %eax //参数一，也就是当前协程地址放到eax
	movl 4(%esp), %esp // 参数一的地址放进esp，因为这个结构，刚好是要切换出去的协程的的寄存器缓存地址
	leal 32(%esp), %esp //parm a : &regs[7] + sizeof(void*)	//给寄存器的地址+8，因为栈只能从高往低操作，而堆是从低往高的，所以挪到末尾，因为push操作会减sp的值

	pushl %eax //esp ->parm a //参数一地址压栈，主要是为了保存住sp+4的地址

	pushl %ebp
	pushl %esi
	pushl %edi
	pushl %edx
	pushl %ecx
	pushl %ebx
	pushl -4(%eax)  //缓存的返回地址压栈

	
	movl 4(%eax), %esp //parm b -> &regs[0]  //相当于sp+8,就是目标协程的地址放到eax

	popl %eax  //ret func addr  //最后压入的是返回地址
	popl %ebx  
	popl %ecx
	popl %edx
	popl %edi
	popl %esi
	popl %ebp
	popl %esp	//前一个栈的参数1地址，也就是sp+的地址，下面在push %eax，那么sp刚好回到原位，而且返回地址刚好处于当前的栈顶。x86 ret函数之前，会插入sp=bp,bp=pop
	pushl %eax //set ret func addr 下面在push %eax，那么sp刚好回到原位，而且返回地址刚好处于当前的栈顶。x86 ret函数之前，会插入sp=bp,bp=pop，
                   //反汇编的的时候，这里看到的是leaveq,就是这个意思

	xorl %eax, %eax
	ret		//现在栈顶是返回地址，所有的寄存器都恢复了，sp也指向了共享栈的位置，ret操作，直接执行栈顶指向的代码，就ok了。

#elif defined(__x86_64__)
	leaq 8(%rsp),%rax
	leaq 112(%rdi),%rsp
	pushq %rax
	pushq %rbx
	pushq %rcx
	pushq %rdx

	pushq -8(%rax) //ret func addr

	pushq %rsi
	pushq %rdi
	pushq %rbp
	pushq %r8
	pushq %r9
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	
	movq %rsi, %rsp
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %r9
	popq %r8
	popq %rbp
	popq %rdi
	popq %rsi
	popq %rax //ret func addr
	popq %rdx
	popq %rcx
	popq %rbx
	popq %rsp
	pushq %rax
	
	xorl %eax, %eax
	ret
#endif
