# Description:
#   Get short-term weather forecast from ninetan.
#
# Dependencies:
#   cron
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


isRaining = (area="tokyo") ->
  switch area
    when "tokyo"
      return robot.brain.get(NINETAN_KOMABA_BRAIN_KEY)
    when "kyoto"
      return robot.brain.get(NINETAN_KRP_BRAIN_KEY)
    else
      return null


startsToRain = (area="tokyo") ->
  switch area
    when "tokyo"
      robot.brain.set(NINETAN_KOMABA_BRAIN_KEY, 1)
    when "kyoto"
      robot.brain.set(NINETAN_KRP_BRAIN_KEY, 1)


stopRaining = (area="tokyo") ->
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

  # get tokyo(KOMABA) forecast
  # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
  new cronJob("30 */10 * * * 1,2,3,4,5", () ->
    unless config.roomId?
      robot.logger.error "process.env.HUBOT_NINETAN_ROOM_ID is not defined"
      return

    robot.http(NINETAN_DATA_TOKYO_KOMABA).get() (err, res, body) ->
      if err
        message = area + "のデータがうまく取れなかったなのっ\n" + NINETAN_DATA_TOKYO_KOMABA
      switch itWillRain(body)

        # it will rain
        when true
          if isRaining("tokyo") == 0
            message = "東京の1時間後の降水確率: " + getPercentage(body) + "% なのっ\n1時間後に雨が降るなのっ\n" + NINTAN_URL_TOKYO
            startsToRain("tokyo")
          break;

        # it will stop rain, or sunny
        when false
          if isRaining("tokyo") == 1
            message = "東京の1時間後の降水確率: " + getPercentage(body) + "% なのっ\n天気は回復だねっ\n" + NINTAN_URL_TOKYO
            stopRaining("tokyo")
        else
          message = "東京のデータがうまく取れなかったなのっ\n" + NINETAN_DATA_TOKYO_KOMABA

      envelope = room: config.roomId
      robot.send envelope, message
  ).start()

  # get kyoto(KRP) forecast
  # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
  new cronJob("30 */10 * * * 1,2,3,4,5", () ->
    unless config.roomId?
      robot.logger.error "process.env.HUBOT_NINETAN_ROOM_ID is not defined"
      return

    message = ""
    robot.http(NINETAN_DATA_KYOTO_KRP).get() (err, res, body) ->
      if err
        message = area + "のデータがうまく取れなかったなのっ\n" + NINETAN_DATA_KYOTO_KRP
      switch itWillRain(body)

        # it will rain
        when true
          if isRaining("kyoto") == 0
            message = "京都の1時間後の降水確率: " + getPercentage(body) + "% なのっ\n1時間後に雨が降るなのっ\n" + NINTAN_URL_KYOTO
            startsToRain("kyoto")
          break;

        # it will stop rain, or sunny
        when false
          if isRaining("kyoto") == 1
            message = "京都の1時間後の降水確率: " + getPercentage(body) + "% なのっ\n天気は回復だねっ\n" + NINTAN_URL_KYOTO
            stopRaining("kyoto")

        else
          message = "京都のデータがうまく取れなかったなのっ\n" + NINETAN_DATA_KYOTO_KRP

      envelope = room: config.roomId
      robot.send envelope, message
  ).start()
