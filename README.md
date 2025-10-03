# TradePro

TradePro is an iOS application that allows traders to log, analyze, and improve their trading performance. The app also provides premium daily stock signals for selected instruments.

---

## Features

* 📈 **Trade Journal**: Log trades with entry/exit prices, instruments, notes, and tags.
* 📊 **Analytics Dashboard**: Visualize profit/loss trends, win-loss ratios, and performance metrics.
* 🔔 **Daily Trade Signals**: Get curated signals for select premium stocks.
* 🔎 **Filtering & Tagging**: Organize trades by strategy, ticker, or tag.
* 💾 **Data Persistence**: Securely store trade history on-device.
* 📤 **Export Options**: Export journal data to CSV/JSON for backups or external analysis.

---

## Requirements

* iOS **14.0+**
* Xcode **15+**
* Swift **5.0+**

---

## Installation & Setup

1. Clone this repository:

   ```bash
   git clone https://github.com/samsumeet/TradePro.git
   cd TradePro
   ```

2. Open the project in Xcode:

   ```bash
   open TradePro.xcodeproj
   ```

3. Install dependencies (if using Swift Package Manager, packages will auto-resolve).

4. Set your signing & team in project settings.

5. Run on simulator or device.

---

## Project Structure

* `TradePro/` → Main iOS app source code (Swift, SwiftUI/UIKit)
* `TradeProTests/` → Unit tests
* `TradeProUITests/` → UI automation tests

---

## Technologies Used

* **Language**: Swift
* **UI**: SwiftUI (with UIKit where needed)
* **Persistence**: Core Data (or another storage engine depending on implementation)
* **Charts/Graphs**: Swift charting library (add details if specific library is used)
* **Testing**: XCTest framework for Unit & UI tests

---

## Usage

* Launch the app on your device.
* Create a new trade entry by specifying instrument, entry/exit, and notes.
* Use filters and tags to review trades by category.
* Analyze performance via charts & metrics.
* Subscribe to unlock daily trade signals.

---

## Roadmap / Future Enhancements

* Cloud sync between devices (iCloud or custom backend)
* Integration with broker APIs for automated import
* Advanced analytics (expectancy, R-multiples, strategy performance)
* Push notifications for signals
* Dark mode & UI themes
* Localization & multi-language support

---

## Contributing

Contributions are welcome! To contribute:

1. Fork the repo
2. Create a new feature branch (`git checkout -b feature/your-feature`)
3. Commit and push your changes
4. Open a Pull Request

Please follow Swift best practices and ensure all tests pass.

---

## License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.

---

## Contact

* Author: [@samsumeet](https://github.com/samsumeet)
* Email: [sumeetbachchas@gmail.com](mailto:sumeetbachchas@gmail.com)
