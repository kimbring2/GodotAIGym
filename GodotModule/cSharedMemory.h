/* cSharedMemory.h */

#ifndef CSHAREDMEMORY_H
#define CSHAREDMEMORY_H

#include "core/object/ref_counted.h"
#include "core/typedefs.h"
#include "core/io/resource_loader.h"
#include "core/variant/variant_parser.h"
#include "core/variant/typed_array.h"
#include "core/variant/variant.h"
#include "core/config/project_settings.h"
#include "core/string/ustring.h"

#include <string>
#include <vector>
#include <exception>
#include <iostream>
#include <istream>
#include <streambuf>
#include <typeinfo>
#include <bits/stdc++.h>

#include <torch/script.h>
#include <torch/csrc/jit/serialization/export.h>
using namespace torch::indexing;


#include <boost/interprocess/managed_shared_memory.hpp>
#include <boost/interprocess/shared_memory_object.hpp>
#include <boost/interprocess/mapped_region.hpp>
#include <boost/interprocess/sync/interprocess_semaphore.hpp>
#include <boost/exception/all.hpp>


using namespace boost::interprocess;

typedef allocator<int, managed_shared_memory::segment_manager>  ShmemAllocatorInt;
typedef allocator<float, managed_shared_memory::segment_manager>  ShmemAllocatorFloat;
typedef allocator<uint8_t, managed_shared_memory::segment_manager>  ShmemAllocatorUint;
typedef std::vector<int, ShmemAllocatorInt> IntVector;
typedef std::vector<float, ShmemAllocatorFloat> FloatVector;
typedef std::vector<uint8_t, ShmemAllocatorUint> UintVector;


class cPersistentIntTensor : public RefCounted {
    GDCLASS(cPersistentIntTensor, RefCounted);

    private:
        IntVector *vector = NULL;
        int size;

    protected:
        static void _bind_methods();

    public:
        cPersistentIntTensor(IntVector *_vector) {
            vector = _vector;
            size = _vector->size();
        }

        ~cPersistentIntTensor() {}

        void write(const PackedInt32Array &array) {
            //print_line(String("Write int vector:"+String(String::num_int64(size))));
            for(int i = 0; i < size; i++)
                (*vector)[i] = array[i];
        };

        PackedInt32Array read() {
            //print_line(String("Read int vector:"+String(String::num_int64(size))));
            PackedInt32Array data;
            for(int i = 0; i < size; i++)
                data.push_back((*vector)[i]);

            return data;
        } 
};


class cPersistentFloatTensor : public RefCounted {
    GDCLASS(cPersistentFloatTensor, RefCounted);

    private:
        FloatVector *vector = NULL;
        int size;

    protected:
        static void _bind_methods();

    public:
        cPersistentFloatTensor(FloatVector *_vector) {
            vector = _vector;
            size = _vector->size();
        }

        ~cPersistentFloatTensor() {}

        void write(const PackedFloat32Array &array) {
            //print_line(String("Write float vector:"+String(String::num_int64(size))));
            for (int i = 0; i < size; i++)
                (*vector)[i] = array[i];
        }

        PackedFloat32Array read(){
            //print_line(String("Read float vector:"+String(String::num_int64(size))));
            PackedFloat32Array data;
            for(int i = 0; i < size; i++)
                data.push_back((*vector)[i]);

            return data;
        }
};


class cPersistentUintTensor : public RefCounted {
    GDCLASS(cPersistentUintTensor, RefCounted);

    private:
        UintVector *vector = NULL;
        int size;

    protected:
        static void _bind_methods();

    public:
        cPersistentUintTensor(UintVector *_vector) {
            vector = _vector;
            size = _vector->size();
        }

        ~cPersistentUintTensor() {}

        void write(const PackedByteArray &array) {
            const uint8_t* uint8Array = reinterpret_cast<const uint8_t*>(array.ptr());
            uint8_t* newArray = new uint8_t[size];
            //memcpy(vector->data(), newArray, size);
            std::memcpy(newArray, uint8Array, size);
            vector->assign(newArray, newArray + size);

            delete newArray;
        }

        PackedByteArray read(){
            //print_line(String("Read float vector:"+String(String::num_int64(size))));
            PackedByteArray data;
            for (int i = 0; i < size; i++)
                data.push_back((*vector)[i]);

            return data;
        }
};


class cSharedMemory : public RefCounted {
    GDCLASS(cSharedMemory, RefCounted);

    int count;

private:
    std::string *segment_name = NULL;
    managed_shared_memory *segment = NULL;
    bool found;

protected:
    static void _bind_methods();

public:
    cSharedMemory();
    ~cSharedMemory();

    Ref<cPersistentIntTensor> findIntTensor(const String &name);
    Ref<cPersistentUintTensor> findUintTensor(const String &name);
    Ref<cPersistentFloatTensor> findFloatTensor(const String &name);

    bool exists();
    String getSegmentName();
};


class cSharedMemorySemaphore : public RefCounted {
    GDCLASS(cSharedMemorySemaphore, RefCounted);
    private:
        std::string *name;
        mapped_region *region;
        interprocess_semaphore *mutex;
    
    protected:
        static void _bind_methods();
    
    public:
        cSharedMemorySemaphore() {;};
        ~cSharedMemorySemaphore() {
            //shared_memory_object::remove(name->c_str());
            delete region;
            delete name;
            delete mutex;
        };

        void init(const String &sem_name) {
            std::string s_name = sem_name.ascii().get_data();
            //std::string s_name(ws.begin(), ws.end());
            //std::string s_name = sem_name.ascii().get_data();
            name = new std::string(s_name);
            std::cout << "Constructing semaphore " << *name << std::endl;

            try {
                shared_memory_object object(open_only, name->c_str(), read_write);
                region = new mapped_region(object, read_write);
            } catch (interprocess_exception &e) {
                //print_line(String("cSharedMemorySemaphore:init:")+String((*name).c_str())+String(":")+String(boost::diagnostic_information(e).c_str()));
                //shared_memory_object::remove(name->c_str());
                ;
            }

            // std::cout<<"Constructed semaphore "<<*name<<std::endl;
        };

        void post() {
            // std::cout<<"Post semaphore "<<*name<<std::endl;
            mutex = static_cast<interprocess_semaphore*>(region->get_address());
            mutex->post();
            // std::cout<<"Posted semaphore "<<*name<<std::endl;
        };

        void wait() {
            // std::cout<<"Wait semaphore "<<*name<<std::endl;
            mutex = static_cast<interprocess_semaphore*>(region->get_address());
            mutex->wait();
            // std::cout<<"Waited semaphore "<<*name<<std::endl;
        };
};

#endif // CSHAREDMEMORY_H