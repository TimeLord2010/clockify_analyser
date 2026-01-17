bool isBeginOfMonth(DateTime dt) {
  if (dt.day != 1 || dt.second != 0) {
    return false;
  }

  if (dt.minute == 0 && dt.hour == 0) {
    return true;
  }

  Duration timezoneOffset = DateTime.now().timeZoneOffset;
  var helper = DateTime(2020, 1, 1);
  helper = helper.add(timezoneOffset);

  return dt.hour == helper.hour && dt.minute == helper.minute;
}
