// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
// A present null is an intentional unavailable route, not a missing override.
export function resolveInstallCommand(method, skill, marketplace, override) {
  if (override != null && (typeof override !== "object" || Array.isArray(override))) {
    throw new TypeError(`Invalid installation override for ${skill.slug}/${method.id}`);
  }
  const command = override && Object.hasOwn(override, "command")
    ? override.command
    : method.command(skill, marketplace);
  if (command !== null && (typeof command !== "string" || !command.trim())) {
    throw new TypeError(`Installation command must be a nonempty string or null: ${skill.slug}/${method.id}`);
  }
  return command;
}
