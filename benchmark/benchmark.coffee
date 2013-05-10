#!/usr/bin/env phantomjs

page = new WebPage()

# Don't supress console output
page.onConsoleMessage = (msg) ->
  console.log msg

  # Terminate when the reporter singals that testing is over.
  # We cannot use a callback function for this (because page.evaluate is sandboxed),
  # so we have to *observe* the website.
  if msg == "done"
    phantom.exit()

page.open "test.html", (status) ->
  console.log(status)
  if status != "success"
    console.log "can't load the address!"
    phantom.exit 1
