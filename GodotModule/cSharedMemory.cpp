/* cSharedMemory.cpp */
#include "cSharedMemory.h"

#include <core/os/os.h>

#include <cstdlib> //std::system
#include <cstddef>
#include <cassert>
#include <utility>

using namespace boost::interprocess;

typedef std::string MyType;

cSharedMemory::cSharedMemory() {
	//print_line(String("cSharedMemory:"));

	count = 0;

	OS *os = reinterpret_cast<OS*>(OS::get_singleton());

	found = false;
	std::string arg_s_name;

	List<String> cmdline_args = OS::get_singleton()->get_cmdline_args();
	for (List<String>::Element *E = cmdline_args.front(); E; E = E->next()) {
		std::string arg_s_name = E->get().ascii().get_data();
		//print_line(String("arg_s_name:") + String(arg_s_name.c_str()));
		//std::string arg_s_name(arg_s.begin(), arg_s.end());

		if (arg_s_name.compare(std::string("--handle")) == 0) {
			std::string val_s = E->next()->get().ascii().get_data();
			segment_name = new std::string(val_s);
			//print_line(String("segment_name:") + String("test name"));
			found = true;
			print_line(String("Shared memory handle found:") + E->get().ascii().get_data() + String(":") + E->next()->get().ascii().get_data());
		}
	}

	if (!found)
		return;
	
	try {
		segment = new managed_shared_memory(open_only, segment_name->c_str());
		if (segment == NULL) {
			print_line(String("cSharedMemory") + String("Memory segment not found"));
		}
	} catch (boost::interprocess::interprocess_exception &e) {
		print_line(String("cSharedMemory")+String(boost::diagnostic_information(e).c_str()));
		shared_memory_object::remove(segment_name->c_str());
	} catch(const char *s) {
		print_line(String("cSharedMemory")+String(s));
	}
}


cSharedMemory::~cSharedMemory() {
	//shared_memory_object::remove(segment_name->c_str());
    delete segment;
    delete segment_name;
};


bool cSharedMemory::exists() {
	return found;
}


String cSharedMemory::getSegmentName() {
	//std::string *segment_name
	//String test_string("test");
	//return test_string;
	return String(segment_name->c_str());
}


Ref<cPersistentFloatTensor> cSharedMemory::findFloatTensor(const String &name) {
	//std::wstring ws = name.c_str();
	//std::string s_name( ws.begin(), ws.end() );
	std::string s_name = name.ascii().get_data();
	FloatVector *shared_vector = segment->find<FloatVector>(s_name.c_str()).first;
	if (shared_vector == NULL) {
		//print_line(String("Not found:")+String(String::num_int64(s_name.length())));
		//print_line(String("Not found:")+String(s_name.c_str()));
		;
	} else {
		//print_line(String("Found:")+String(s_name.c_str()));
		;
	}

	Ref<cPersistentFloatTensor> tensor(memnew(cPersistentFloatTensor(shared_vector)));
	
	return tensor;
}


Ref<cPersistentIntTensor> cSharedMemory::findIntTensor(const String &name) {
	std::string s_name = name.ascii().get_data();
	IntVector *shared_vector = segment->find<IntVector> (s_name.c_str()).first;
	if (shared_vector == NULL){
		// print_line(String("Not found:")+String(String::num_int64(s_name.length())));
		//print_line(String("Not found:")+String(s_name.c_str()));
		;
	} else {
		//print_line(String("Found:")+String(s_name.c_str()));
		;
	}

	Ref<cPersistentIntTensor> tensor(memnew(cPersistentIntTensor(shared_vector)));
	
	return tensor;
}


Ref<cPersistentUintTensor> cSharedMemory::findUintTensor(const String &name) {
	std::string s_name = name.ascii().get_data();
	UintVector *shared_vector = segment->find<UintVector> (s_name.c_str()).first;
	if(shared_vector == NULL) {
		// print_line(String("Not found:")+String(String::num_int64(s_name.length())));
		//print_line(String("Not found:")+String(s_name.c_str()));
		;
	} else {
		//print_line(String("Found:")+String(s_name.c_str()));
		;
	}

	Ref<cPersistentUintTensor> tensor(memnew(cPersistentUintTensor(shared_vector)));

	return tensor;
}


void cPersistentFloatTensor::_bind_methods() {
	ClassDB::bind_method(D_METHOD("read"), &cPersistentFloatTensor::read);
	ClassDB::bind_method(D_METHOD("write", "array"), &cPersistentFloatTensor::write);
}


void cPersistentIntTensor::_bind_methods() {
	ClassDB::bind_method(D_METHOD("read"), &cPersistentIntTensor::read);
	ClassDB::bind_method(D_METHOD("write", "array"), &cPersistentIntTensor::write);
}


void cPersistentUintTensor::_bind_methods(){
	ClassDB::bind_method(D_METHOD("read"), &cPersistentUintTensor::read);
	ClassDB::bind_method(D_METHOD("write", "array"), &cPersistentUintTensor::write);
}


void cSharedMemory::_bind_methods() {
	ClassDB::bind_method(D_METHOD("findIntTensor", "str"), &cSharedMemory::findIntTensor);
	ClassDB::bind_method(D_METHOD("findFloatTensor", "str"), &cSharedMemory::findFloatTensor);
	ClassDB::bind_method(D_METHOD("findUintTensor", "str"), &cSharedMemory::findUintTensor);

	ClassDB::bind_method(D_METHOD("exists"), &cSharedMemory::exists);
	ClassDB::bind_method(D_METHOD("getSegmentName"), &cSharedMemory::getSegmentName);
}


void cSharedMemorySemaphore::_bind_methods() {
	ClassDB::bind_method(D_METHOD("post"), &cSharedMemorySemaphore::post);
	ClassDB::bind_method(D_METHOD("wait"), &cSharedMemorySemaphore::wait);
	ClassDB::bind_method(D_METHOD("init", "str"), &cSharedMemorySemaphore::init);
}
