#pragma once

#include <string>

#include "core/types.hpp"

namespace cxpt {

[[nodiscard]] ParseResult parseXptFile(const std::string &path);

} // namespace cxpt
