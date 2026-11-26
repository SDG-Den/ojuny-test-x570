#include <cstring>
#include <iostream>
#include <leveldb/db.h>
#include <string>

namespace {

int write_storage(const std::string &path, const std::string &user_id) {
  leveldb::Options options;
  options.create_if_missing = true;

  leveldb::DB *database = nullptr;
  leveldb::Status status = leveldb::DB::Open(options, path, &database);
  if (!status.ok()) {
    std::cerr << status.ToString() << "\n";
    return 1;
  }

  status = database->Put(leveldb::WriteOptions(), "alreadyInstalled", "true");
  if (status.ok()) {
    status = database->Put(leveldb::WriteOptions(), "userID", "\"" + user_id + "\"");
  }
  delete database;

  if (!status.ok()) {
    std::cerr << status.ToString() << "\n";
    return 1;
  }
  return 0;
}

int check_storage(const std::string &path, const std::string &user_id) {
  leveldb::DB *database = nullptr;
  leveldb::Status status = leveldb::DB::Open(leveldb::Options(), path, &database);
  if (!status.ok()) {
    std::cerr << status.ToString() << "\n";
    return 1;
  }

  std::string installed;
  std::string stored_id;
  status = database->Get(leveldb::ReadOptions(), "alreadyInstalled", &installed);
  if (status.ok()) {
    status = database->Get(leveldb::ReadOptions(), "userID", &stored_id);
  }
  delete database;

  if (!status.ok()) {
    std::cerr << "missing seeded keys\n";
    return 1;
  }
  if (installed != "true" || stored_id != "\"" + user_id + "\"") {
    std::cerr << "seeded keys do not match\n";
    return 1;
  }
  return 0;
}

} // namespace

int main(int argc, char **argv) {
  if (argc == 4 && std::strcmp(argv[1], "--check") == 0) {
    return check_storage(argv[2], argv[3]);
  }
  if (argc == 3) {
    return write_storage(argv[1], argv[2]);
  }
  std::cerr << "usage: seed-extension-storage [--check] <db-path> <user-id>\n";
  return 2;
}
