/* register_types.cpp */

#include "register_types.h"

#include "core/object/class_db.h"
#include "cSharedMemory.h"

void initialize_csharedmemory_module(ModuleInitializationLevel p_level) {
   if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
         return;
   }
   ClassDB::register_class<cSharedMemory>();
   ClassDB::register_class<cSharedMemorySemaphore>();
}

void uninitialize_csharedmemory_module(ModuleInitializationLevel p_level) {
   if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
         return;
   }
   // Nothing to do here in this example.
}