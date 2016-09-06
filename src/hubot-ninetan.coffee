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

NINETAN_DATA_TOKYO_COMABA = "http://sx9.jp/weather/tokyo-komaba.js"
NINETAN_DATA_KYOTO_KRP = "http://sx9.jp/weather/kyoto-krp.js"
NINETAN_URL_TOKYO = "http://sx9.jp/weather/tokyo.html"
NINETAN_URL_KYOTO = "http://sx9.jp/weather/kyoto.html"


itWillRain = (ninetan_databody) ->
    data = ninetan_databody.split("\n")
    match1 = data[483].match(/\(.+\,.+\,.+\)/)
    if match1
      value = parseInt match1[0].split(",")[2].slice(1, -1)

      if value >= 25
        return true
      else
        return false


getPercentage = (ninetan_databody) ->
  data = ninetan_databody.split("\n")
  match1 = data[483].match(/\(.+\,.+\,.+\)/)
  return parseInt match1[0].split(",")[2].slice(1, -1)


checkNineTan = (msg, area="tokyo") ->
  switch area
    when "tokyo"
      ninetan_data = NINETAN_DATA_TOKYO_COMABA
      ninetan_url = NINETAN_URL_TOKYO
    when "東京"
      ninetan_data = NINETAN_DATA_TOKYO_COMABA
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

    robot.http(NINETAN_DATA_TOKYO_COMABA).get() (err, res, body) ->
      if err
        message = area + "のデータがうまく取れなかったなのっ\n" + NINETAN_DATA_TOKYO_COMABA
      switch itWillRain(body)
        when true
          message = "東京の1時間後の降水確率: " + getPercentage(body) + "% なのっ\n1時間後に雨が降るなのっ\n" + NINTAN_URL_TOKYO
        when false
          message = "東京の1時間後の降水確率: " + getPercentage(body) + "% なのっ\n" + NINTAN_URL_TOKYO
        else
          message = "東京のデータがうまく取れなかったなのっ\n" + NINETAN_DATA_TOKYO_COMABA

      envelope = room: config.roomId
      robot.send envelope, message
  ).start()

  # get kyoto(KRP) forecast
  # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
  new cronJob("30 */10 * * * 1,2,3,4,5", () ->
    unless config.roomId?
      robot.logger.error "process.env.HUBOT_NINETAN_ROOM_ID is not defined"
      return

    robot.http(NINETAN_DATA_KYOTO_KRP).get() (err, res, body) ->
      if err
        message = area + "のデータがうまく取れなかったなのっ\n" + NINETAN_DATA_KYOTO_KRP
      switch itWillRain(body)
        when true
          message = "京都の1時間後の降水確率: " + getPercentage(body) + "% なのっ\n1時間後に雨が降るなのっ\n" + NINTAN_URL_KYOTO
          break;
        when false
          message = "京都の1時間後の降水確率: " + getPercentage(body) + "% なのっ\n" + NINTAN_URL_KYOTO
        else
          message = "京都のデータがうまく取れなかったなのっ\n" + NINETAN_DATA_KYOTO_KRP

      envelope = room: config.roomId
      robot.send envelope, message
  ).start()
