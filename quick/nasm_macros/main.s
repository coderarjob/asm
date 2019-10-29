
%define TRUE 1
	mov eax, TRUE

%define TRUE 0
	mov eax, TRUE

%macro POP 1-*

	%rep %0			; %0 is the argument count
	    pop %1
	    %rotate 1		; %rotate x, rotates parameters x times to the
				; left, -x rotates x times to the right.
	%endrep

%endmacro

POP eax, ebx, ecx, edx

%error Cannot continue.
