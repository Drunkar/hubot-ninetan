# Description:
#   Get short-term weather forecast from ninetan.
#
# Dependencies:
#   HUBOT_NINETAN_ROOM_ID: slack room id.
#   HUBOT_NINETAN_CRON_AREAS: ["tokyo", "kyoto"]
#
# Configuration:
#   None
#
# Commands:
#   hubot ninetan|ないんたん 東京|tokyo|京都|kyoto
#
# Author:
#   Drunkar <drunkars.p@gmail.com>
#

cronJob = require('cron').CronJob

config =
  roomId: process.env.HUBOT_NINETAN_ROOM_ID
  cronAreas: JSON.parse(process.env.HUBOT_NINETAN_CRON_AREAS ? '[]')

NINETAN_DATA_TOKYO_KOMABA = "http://sx9.jp/weather/tokyo-komaba.js"
NINETAN_DATA_KYOTO_KRP = "http://sx9.jp/weather/kyoto-krp.js"
NINETAN_URL_TOKYO = "http://sx9.jp/weather/tokyo.html"
NINETAN_URL_KYOTO = "http://sx9.jp/weather/kyoto.html"
NINETAN_KRP_BRAIN_KEY = "ninetan_krp"
NINETAN_KOMABA_BRAIN_KEY = "ninetan_komaba"


itWillRain = (ninetan_databody) ->
    data = ninetan_databody.split("\n")
    match1 = data[483].match(/\(.+\,.+\,.+\)/)
    if match1
      value = parseInt match1[0].split(",")[2].slice(1, -1)

      if value >= 25
        return true
      else
        return false


isRaining = (robot, area="tokyo") ->
  switch area
    when "tokyo"
      return robot.brain.get(NINETAN_KOMABA_BRAIN_KEY)
    when "kyoto"
      return robot.brain.get(NINETAN_KRP_BRAIN_KEY)
    else
      return -1


startsToRain = (robot, area="tokyo") ->
  switch area
    when "tokyo"
      robot.brain.set(NINETAN_KOMABA_BRAIN_KEY, 1)
    when "kyoto"
      robot.brain.set(NINETAN_KRP_BRAIN_KEY, 1)


stopRaining = (robot, area="tokyo") ->
  switch area
    when "tokyo"
      robot.brain.set(NINETAN_KOMABA_BRAIN_KEY, 0)
    when "kyoto"
      robot.brain.set(NINETAN_KRP_BRAIN_KEY, 0)


getPercentage = (ninetan_databody) ->
  data = ninetan_databody.split("\n")
  match1 = data[483].match(/\(.+\,.+\,.+\)/)
  return parseInt match1[0].split(",")[2].slice(1, -1)


checkNineTan = (msg, area="tokyo") ->
  switch area
    when "tokyo"
      ninetan_data = NINETAN_DATA_TOKYO_KOMABA
      ninetan_url = NINETAN_URL_TOKYO
    when "東京"
      ninetan_data = NINETAN_DATA_TOKYO_KOMABA
      ninetan_url = NINETAN_URL_TOKYO
    when "kyoto"
      ninetan_data = NINETAN_DATA_KYOTO_KRP
      ninetan_url = NINETAN_URL_KYOTO
    when "京都"
      ninetan_data = NINETAN_DATA_KYOTO_KRP
      ninetan_url = NINETAN_URL_KYOTO
    else
      msg.send "東京か京都しか対応してないよっ"
      return

  msg.http(ninetan_data).get() (err, res, body) ->
    if err
      message = area + "のデータがうまく取れなかったなのっ\n" + ninetan_data
    switch itWillRain(body)
      when true
        message = area + "の1時間後の降水確率: " + getPercentage(body) + "% なのっ\n1時間後に雨が降るなのっ\n" + ninetan_url
      when false
        message = area + "の1時間後の降水確率: " + getPercentage(body) + "% なのっ\n" + ninetan_url
      else
        message = area + "のデータがうまく取れなかったなのっ\n" + ninetan_data

    msg.send message


module.exports = (robot) ->

  robot.respond /(ninetan|ないんたん)$/i, (msg) ->
    checkNineTan(msg)

  robot.respond /((ninetan|ないんたん) (.+))/i, (msg) ->
    checkNineTan(msg, msg.match[3].toLowerCase())

  if "tokyo" in config.cronAreas
    # get tokyo(KOMABA) forecast
    # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
    new cronJob("30 */10 * * * *", () ->
      unless config.roomId?
        robot.logger.error "process.env.HUBOT_NINETAN_ROOM_ID is not defined"
        return

      message = ""
      robot.http(NINETAN_DATA_TOKYO_KOMABA).get() (err, res, body) ->
        if err
          message = "東京のデータがうまく取れなかったなのっ\n" + NINETAN_DATA_TOKYO_KOMABA
        switch itWillRain(body)

          # it will rain
          when true
            if isRaining(robot, "tokyo") in [0, null]
              message = "東京の1時間後の降水確率: " + getPercentage(body) + "% なのっ\n1時間後に雨が降るなのっ\n" + NINETAN_URL_TOKYO
              startsToRain(robot, "tokyo")
            break;

          # it will stop rain, or sunny
          when false
            if isRaining(robot, "tokyo") in [1, null]
              message = "東京の1時間後の降水確率: " + getPercentage(body) + "% なのっ\n天気は回復だねっ\n" + NINETAN_URL_TOKYO
              stopRaining(robot, "tokyo")
          else
            message = "東京のデータがうまく取れなかったなのっ\n" + NINETAN_DATA_TOKYO_KOMABA

        envelope = room: config.roomId
        robot.send envelope, message
    ).start()

  if "kyoto" in config.cronAreas
    # get kyoto(KRP) forecast
    # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
    new cronJob("30 */10 * * * *", () ->
      unless config.roomId?
        robot.logger.error "process.env.HUBOT_NINETAN_ROOM_ID is not defined"
        return

      message = ""
      robot.http(NINETAN_DATA_KYOTO_KRP).get() (err, res, body) ->
        if err
          message = "京都のデータがうまく取れなかったなのっ\n" + NINETAN_DATA_KYOTO_KRP
        switch itWillRain(body)

          # it will rain
          when true
            if isRaining(robot, "kyoto") in [0, null]
              message = "京都の1時間後の降水確率: " + getPercentage(body) + "% なのっ\n1時間後に雨が降るなのっ\n" + NINETAN_URL_KYOTO
              startsToRain(robot, "kyoto")
            break;

          # it will stop rain, or sunny
          when false
            if isRaining(robot, "kyoto") in [1, null]
              message = "京都の1時間後の降水確率: " + getPercentage(body) + "% なのっ\n天気は回復だねっ\n" + NINETAN_URL_KYOTO
              stopRaining(robot, "kyoto")
          else
            message = "京都のデータがうまく取れなかったなのっ\n" + NINETAN_DATA_KYOTO_KRP

        envelope = room: config.roomId
        robot.send envelope, message
    ).start()
