import SwiftUI


struct ForecastTable_Previews: PreviewProvider {
    static var previews: some View {
    let bestWindDirections = ["N"]
    let lowTide = "Yes"
    let midTide = "Yes"
    let highTide = "No"

        // Provide sample records for preview purposes
        ForecastTable(
            records: [
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-15T15:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 1,
                    relativeDirection: "sideshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "14:00",
                    extremeType: "High"
                )),
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-15T16:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 120,
                    relativeDirection: "onshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "",
                    extremeType: "High"
                )),
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-15T17:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 80,
                    relativeDirection: "offshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "",
                    extremeType: "High"
                )),
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-15T18:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 80,
                    relativeDirection: "offshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "",
                    extremeType: "High"
                )),
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-15T19:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 80,
                    relativeDirection: "offshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "",
                    extremeType: "High"
                )),
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-15T20:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 80,
                    relativeDirection: "offshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "",
                    extremeType: "High"
                )),
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-15T21:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 80,
                    relativeDirection: "offshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "",
                    extremeType: "High"
                )),
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-15T22:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 80,
                    relativeDirection: "offshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "",
                    extremeType: "High"
                )),
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-15T23:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 80,
                    relativeDirection: "offshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "",
                    extremeType: "High"
                )),
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-16T00:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 80,
                    relativeDirection: "offshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "",
                    extremeType: "High"
                )),
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-16T01:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 80,
                    relativeDirection: "offshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "",
                    extremeType: "High"
                )),
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-16T02:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 80,
                    relativeDirection: "offshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "",
                    extremeType: "High"
                )),
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-16T03:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 80,
                    relativeDirection: "offshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "",
                    extremeType: "High"
                )),
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-16T04:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 80,
                    relativeDirection: "offshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "",
                    extremeType: "High"
                )),
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-16T05:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 80,
                    relativeDirection: "offshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "",
                    extremeType: "High"
                )),
                Record(fields: RecordFields(
                    spotName: "Pont-Mahe",
                    timestamp: "2024-01-16T06:00:00.000Z",
                    windSpeed: 10.0,
                    windGust: 15.0,
                    windDegrees: 80,
                    relativeDirection: "offshore",
                    tideDescription: "low",
                    tideHeight: -1.977,
                    tidePracticable: "Yes",
                    spotId: "pontmahe",
                    model: "meteofrance_arome_france_hd",
                    extremeHour: "",
                    extremeType: "High"
                ))
            ],
            bestWindDirection: bestWindDirections,
            lowTide: lowTide,
            midTide: midTide,
            highTide: highTide

        )
        .previewLayout(.sizeThatFits)
    }
}
