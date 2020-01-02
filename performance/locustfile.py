from locust import HttpLocust, seq_task, task, TaskSequence, TaskSet, between
import random
import uuid

class PlayGame(TaskSet):
  @task(1)
  def play(self):
    possible_actions_url = self.locust.data["game_possible_actions_url"]
    possible_actions_body = self.client.get(possible_actions_url, name = "/api/games/:gameId/possible-actions").json()

    possible_actions = possible_actions_body["_embedded"]["boardr:possible-actions"]
    if not possible_actions:
      return self.interrupt()

    action = random.choice(possible_actions)
    action_request_body = { key: action[key] for key in ["type", "position"] }
    actions_url = self.locust.data["game_actions_url"]
    self.client.post(actions_url, None, action_request_body, headers = {
      "Authorization": "Bearer " + self.locust.data["token"]
    }, name = "/api/games/:gameId/actions")

class CreateAndPlayGame(TaskSequence):
  @seq_task(1)
  def create_game(self):
    games_url = self.locust.data["games_url"]
    game_body = self.client.post(games_url, None, {
      "rules": "tic-tac-toe"
    }, headers = {
      "Authorization": "Bearer " + self.locust.data["token"]
    }).json()

    self.locust.data["game_actions_url"] = game_body["_links"]["boardr:actions"]["href"]
    self.locust.data["game_url"] = game_body["_links"]["self"]["href"]
    self.locust.data["game_possible_actions_url"] = game_body["_links"]["boardr:possible-actions"]["href"]

class JoinAndPlayRandomGame(TaskSequence):
  @seq_task(1)
  def join_random_game(self):
    games_url = self.locust.data["games_url"]
    games_body = self.client.get(games_url, params = {
      "state": "waiting_for_players"
    }).json()

    available_games = games_body["_embedded"]["boardr:games"]
    if not available_games:
      self.interrupt()

    random_game = random.choice(available_games)
    random_game_players_url = random_game["_links"]["boardr:players"]["href"]
    self.client.post(random_game_players_url, None, {}, headers = {
      "Authorization": "Bearer " + self.locust.data["token"]
    }, name = "/api/games/:gameId/players")

    self.locust.data["game_actions_url"] = random_game["_links"]["boardr:actions"]["href"]
    self.locust.data["game_url"] = random_game["_links"]["self"]["href"]
    self.locust.data["game_possible_actions_url"] = random_game["_links"]["boardr:possible-actions"]["href"]

class NormalPlayerBehavior(TaskSet):
  tasks = {
    CreateAndPlayGame: 1,
    JoinAndPlayRandomGame: 3
  }

  def on_start(self):
    api_root_body = self.client.get("/api").json()
    self.locust.data["games_url"] = api_root_body["_links"]["boardr:games"]["href"]

    identities_url = api_root_body["_links"]["boardr:identities"]["href"]
    name = self.locust.data["name"] = uuid.uuid4().hex
    identity_body = self.client.post(identities_url, None, {
      "email": name + "@example.com",
      "provider": "local"
    }).json()

    registration_token = identity_body["_embedded"]["boardr:token"]["value"]
    users_url = api_root_body["_links"]["boardr:users"]["href"]
    user_body = self.client.post(users_url, None, {
      "name": name,
      "provider": "local"
    }, headers = {
      "Authorization": "Bearer " + registration_token
    }).json()

    self.locust.data["token"] = user_body["_embedded"]["boardr:token"]["value"]

class WebsiteUser(HttpLocust):
  data = {}
  task_set = NormalPlayerBehavior
  wait_time = between(3, 8)