function shared_memory_delete(state)
%SHARED_MEMORY_DELETE Deletes lightweight backend file.

if isfile(state.file_path)
    delete(state.file_path);
end
end
