// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "TPInAppReceiptX",
    products: [
        .library(name: "TPInAppReceiptX", targets: ["TPInAppReceiptX"]),
    ],
    targets: [
        .target(
            name: "TPInAppReceiptX",
			path: "TPInAppReceipt/Source")
    ]
)
