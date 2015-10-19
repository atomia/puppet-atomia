version = 15.9.10 

all:

clean:
	rm -f *.deb *.rpm
	rm -f atomia-puppetmaster

package: clean all
	./build_package.sh $(version)
