#!/usr/bin/env python3

# Deps not managed by setup.sh since this is optional
#
# sudo apt install python3-pip && python3 -m pip install sh


import json, os, re, sh

class StateFile:
	path = None
	data = None

	def __init__(self, path):
		self.path = str(path)

	def prepare(self, default_state):
		if os.path.exists(self.path):
			self.load()
		else:
			self.data = default_state
			self.save()

	def load(self):
		handle = open(self.path)
		self.data = json.load(handle)
		handle.close()

	def save(self):
		handle = open(self.path, 'w')
		json.dump(self.data, handle, indent=4, sort_keys=False)
		handle.close()

class Watcher:
	log_path     = None
	discord_path = None
	known_users  = None
	known_ids    = None

	def __init__(self):
		admin_dir = os.path.dirname(os.path.realpath(__file__))
		top_dir   = os.path.dirname(admin_dir)

		self.log_path     = os.path.join(top_dir, 'log', 'console', 'vhserver-console.log')
		self.discord_path = os.path.join(admin_dir, 'discord.sh')
		known_users_path  = os.path.join(admin_dir, 'known-names.json')
		known_ids_path    = os.path.join(admin_dir, 'known-ids.json')

		self.known_users = StateFile(known_users_path)
		self.known_ids   = StateFile(known_ids_path)

		self.known_users.prepare([])
		self.known_ids.prepare([])

		print('Loaded', len(self.known_users.data), 'names and', len(self.known_ids.data), 'IDs.')

		self.debugHeaders    = re.compile('\(Filename\: .*.h Line\: [0-9]+\)'           ) # Repetitive debug noise
		self.playerConnected = re.compile('Got character ZDOID from ([a-zA-Z ]{1,20}) :') # Named  join stanza
		self.playerID        = re.compile('Got session request from ([0-9]+)'           ) # Unique join stanza

	def watch_log(self):

		# Native tail turns out to be less of a pain than doing it with python, lol.
		# LGSM rotates the log file frequently, hence the -F flag.
		for line in sh.tail('-F', '-n', '100', self.log_path, _iter=True):

			# Remove windows encoding
			if line.endswith('\r\n'):
				line = line[:-2]

			# Remove noise
			if line == '' or line == ' ' or self.debugHeaders.match(line):
				continue

			# Line is worth processing
			self.handle_line(line)

	def handle_line(self, line):
		print(line)

		# Detect connected player names
		if self.playerConnected.search(line):

			# Extract name from matched group
			player_name = self.playerConnected.search(line).group(1)

			# Low-effort security punting:
			#
			# Shlex or similar is the correct approach. This script does not bother.
			# Should also really just be building the JSON object ourselves instead.
			#
			# Valheim has a fairly strict username policy & the above regex enforces it.
			# More than enough for a friendly, password-protected server. Harden this if desired.

			if player_name in self.known_users.data:
				print('\tAlready seen', player_name)

			else:
				print('\tDiscovered player:', player_name)
				self.known_users.data.append(player_name)
				self.known_users.save()

				message = "New viking: " + player_name + "!"
				cmd = sh.Command(self.discord_path)
				cmd("--text", message)
				print('\tSent discord message (' + message + ')')

		# Detect connected player steamID64s
		elif self.playerID.search(line):
			player_id = self.playerID.search(line).group(1)

			if player_id in self.known_ids.data:
				print('\tAlready seen ID', player_id)
			else:
				print('\tDiscovered ID:', player_id)
				self.known_ids.data.append(player_id)
				self.known_ids.save()


def main():
	Watcher().watch_log()

if __name__ == "__main__":
	try:
		main()
	except KeyboardInterrupt:
		print('\nExit.')

