

# Temporary text files are the worst. 
clean:
	@ echo 'Cleaning up.'
	@- rm *~ *.out *.mod *.pyc &> /dev/null ||:

