import QtQuick
import Quickshell
import "nepali-date.js" as NepCal
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    property color customColor: Theme.primary

    // A fixed red used for Sundays and public holidays
    readonly property color holidayColor: "#ef4444"

    // Today's BS date components (updated hourly via systemClock)
    property string todayBSDate: NepCal.ADToBS(Qt.formatDate(systemClock.date, "yyyy-MM-dd"))
    property int todayBSYear: todayBSDate !== "Error" ? parseInt(todayBSDate.split("-")[0], 10) : 2082
    property int todayBSMonth: todayBSDate !== "Error" ? parseInt(todayBSDate.split("-")[1], 10) : 1
    property int todayBSDay: todayBSDate !== "Error" ? parseInt(todayBSDate.split("-")[2], 10) : 1

    // Calendar view navigation state
    property int viewYear: todayBSYear
    property int viewMonth: todayBSMonth

    // Holiday data fetched from casualsnek/npEventsAPI
    property var holidayData: null
    property int loadedYear: -1
    property bool isLoading: false

    Component.onCompleted: fetchHolidayData(viewYear)
    onViewYearChanged: fetchHolidayData(viewYear)

    function fetchHolidayData(bsYear) {
        if (loadedYear === bsYear || isLoading) return;
        isLoading = true;
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isLoading = false;
                if (xhr.status === 200) {
                    try {
                        holidayData = JSON.parse(xhr.responseText);
                        loadedYear = bsYear;
                    } catch (e) {
                        console.warn("NepaliCalendar: failed to parse holiday data:", e);
                    }
                }
            }
        };
        xhr.open("GET", NepCal.getHolidayArtifactUrl(bsYear));
        xhr.send();
    }

    function navigateMonth(delta) {
        var m = viewMonth + delta;
        var y = viewYear;
        if (m < 1) {
            m = 12;
            y = y - 1;
        }
        if (m > 12) {
            m = 1;
            y = y + 1;
        }
        viewMonth = m;
        viewYear = y;
    }

    // Build the array of calendar cells for a given BS month.
    // Each cell: {day, isToday, isHoliday, isSunday, events[]}
    // day === 0 means an empty leading cell.
    function buildCalendarCells(bsYear, bsMonth, hData, todayYear, todayMonth, todayDay) {
        var daysInMonth = NepCal.getDaysInBSMonth(bsYear, bsMonth);
        var firstWeekday = NepCal.getFirstWeekdayOfBSMonth(bsYear, bsMonth);
        var cells = [];
        for (var i = 0; i < firstWeekday; i++) {
            cells.push({day: 0, isToday: false, isHoliday: false, isSunday: (i === 0), events: []});
        }
        for (var d = 1; d <= daysInMonth; d++) {
            var weekdayIndex = (firstWeekday + d - 1) % 7;
            var isToday = (bsYear === todayYear && bsMonth === todayMonth && d === todayDay);
            var isHoliday = false;
            var events = [];
            if (hData) {
                var key = NepCal.getAdDateKey(bsYear, bsMonth, d);
                var entry = hData[key];
                if (entry) {
                    isHoliday = entry.is_public_holiday === true;
                    events = entry.events || [];
                }
            }
            cells.push({
                day: d,
                isToday: isToday,
                isHoliday: isHoliday,
                isSunday: weekdayIndex === 0,
                events: events
            });
        }
        return cells;
    }

    SystemClock {
        id: systemClock

        precision: SystemClock.Hours
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            StyledText {
                text: NepCal.formatBSDate(NepCal.ADToBS(Qt.formatDate(systemClock.date, "yyyy-MM-dd")), pluginData.dateFormat ?? "YYYY Month dd", pluginData.showDevanagari)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

        }

    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            StyledText {
                text: NepCal.formatBSDateVertical(NepCal.ADToBS(Qt.formatDate(systemClock.date, "yyyy-MM-dd")), pluginData.dateFormat ?? "YYYY Month dd", pluginData.showDevanagari)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

        }

    }

    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: "Nepali Calendar"
            detailsText: ""
            showCloseButton: true

            // Reactively recomputed when any dependency changes
            property var cells: root.buildCalendarCells(root.viewYear, root.viewMonth, root.holidayData, root.todayBSYear, root.todayBSMonth, root.todayBSDay)

            property var monthHolidays: cells.filter(function (c) {
                return c.day > 0 && c.events && c.events.length > 0;
            })

            // Currently selected day (click to see events; click again to deselect)
            property int selectedDay: -1
            property var selectedDayEvents: []

            Column {
                width: parent.width
                spacing: Theme.spacingS

                // ── Month navigation ────────────────────────────────────────
                Row {
                    width: parent.width

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: prevArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                        StyledText {
                            anchors.centerIn: parent
                            text: "‹"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                        }

                        MouseArea {
                            id: prevArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.navigateMonth(-1);
                                popout.selectedDay = -1;
                            }
                        }

                    }

                    Item {
                        width: parent.width - 64
                        height: 32

                        StyledText {
                            anchors.centerIn: parent
                            text: {
                                var m = pluginData.showDevanagari ? NepCal.bsMonthsDevanagari[root.viewMonth - 1] : NepCal.bsMonths[root.viewMonth - 1];
                                var y = pluginData.showDevanagari ? NepCal.toDevanagariDigit(String(root.viewYear)) : String(root.viewYear);
                                return m + " " + y;
                            }
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }

                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: nextArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                        StyledText {
                            anchors.centerIn: parent
                            text: "›"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                        }

                        MouseArea {
                            id: nextArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.navigateMonth(1);
                                popout.selectedDay = -1;
                            }
                        }

                    }

                }

                // ── Weekday headers ─────────────────────────────────────────
                Row {
                    id: weekdayRow

                    width: parent.width

                    property var weekdays: pluginData.showDevanagari ? ["आइत", "सोम", "मंगल", "बुध", "बिहि", "शुक्र", "शनि"] : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

                    Repeater {
                        model: 7

                        Item {
                            width: weekdayRow.width / 7
                            height: 22

                            StyledText {
                                anchors.centerIn: parent
                                text: weekdayRow.weekdays[index]
                                font.pixelSize: Theme.fontSizeXSmall
                                color: index === 0 ? root.holidayColor : Theme.surfaceVariantText
                            }

                        }

                    }

                }

                // ── Calendar date grid ───────────────────────────────────────
                Grid {
                    id: calGrid

                    width: parent.width
                    columns: 7

                    Repeater {
                        model: popout.cells

                        Item {
                            width: calGrid.width / 7
                            height: width

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 4
                                height: parent.height - 4
                                radius: width / 2
                                color: {
                                    if (modelData.day === 0)
                                        return "transparent";
                                    if (modelData.isToday)
                                        return Theme.primary;
                                    if (popout.selectedDay === modelData.day)
                                        return Theme.surfaceContainerHighest;
                                    if (modelData.isHoliday)
                                        return Qt.rgba(0.94, 0.27, 0.27, 0.12);
                                    return "transparent";
                                }
                            }

                            // Small dot indicator for events / holidays
                            Rectangle {
                                visible: modelData.day > 0 && !modelData.isToday && modelData.events.length > 0
                                width: 4
                                height: 4
                                radius: 2
                                color: modelData.isHoliday ? root.holidayColor : Theme.primary
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                anchors.centerIn: parent
                                text: modelData.day === 0 ? "" : (pluginData.showDevanagari ? NepCal.toDevanagariDigit(String(modelData.day)) : String(modelData.day))
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: modelData.isToday ? Font.Bold : Font.Normal
                                color: {
                                    if (modelData.day === 0)
                                        return "transparent";
                                    if (modelData.isToday)
                                        return "white";
                                    if (modelData.isSunday || modelData.isHoliday)
                                        return root.holidayColor;
                                    return Theme.surfaceText;
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: modelData.day > 0
                                cursorShape: modelData.day > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (popout.selectedDay === modelData.day) {
                                        popout.selectedDay = -1;
                                        popout.selectedDayEvents = [];
                                    } else {
                                        popout.selectedDay = modelData.day;
                                        popout.selectedDayEvents = modelData.events;
                                    }
                                }
                            }

                        }

                    }

                }

                // ── Loading indicator ────────────────────────────────────────
                StyledText {
                    visible: root.isLoading
                    width: parent.width
                    text: pluginData.showDevanagari ? "लोड हुँदैछ..." : "Loading holiday data…"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    horizontalAlignment: Text.AlignHCenter
                }

                // ── Selected-day event panel ─────────────────────────────────
                StyledRect {
                    visible: popout.selectedDay > 0 && popout.selectedDayEvents.length > 0
                    width: parent.width
                    height: selectedEventsCol.implicitHeight + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    Column {
                        id: selectedEventsCol

                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingXS

                        StyledText {
                            text: {
                                var d = pluginData.showDevanagari ? NepCal.toDevanagariDigit(String(popout.selectedDay)) : String(popout.selectedDay);
                                var m = pluginData.showDevanagari ? NepCal.bsMonthsDevanagari[root.viewMonth - 1] : NepCal.bsMonths[root.viewMonth - 1];
                                return m + " " + d;
                            }
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }

                        Repeater {
                            model: popout.selectedDayEvents

                            StyledText {
                                text: "• " + modelData
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                width: selectedEventsCol.width
                                wrapMode: Text.WordWrap
                            }

                        }

                    }

                }

                // ── Month event list ─────────────────────────────────────────
                Column {
                    width: parent.width
                    spacing: Theme.spacingXS
                    visible: popout.monthHolidays.length > 0 && !root.isLoading

                    StyledText {
                        text: pluginData.showDevanagari ? "यो महिनाका घटनाहरू" : "Events this month"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    Repeater {
                        model: popout.monthHolidays

                        Row {
                            width: parent.width
                            spacing: Theme.spacingXS

                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: modelData.isHoliday ? root.holidayColor : Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: -1
                            }

                            StyledText {
                                text: {
                                    var d = pluginData.showDevanagari ? NepCal.toDevanagariDigit(String(modelData.day)) : String(modelData.day);
                                    return d + " — " + modelData.events.join(", ");
                                }
                                font.pixelSize: Theme.fontSizeXSmall
                                color: modelData.isHoliday ? root.holidayColor : Theme.surfaceText
                                width: parent.width - 10
                                wrapMode: Text.WordWrap
                            }

                        }

                    }

                }

            }

        }

    }

}
