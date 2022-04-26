//
//  MenuViewModel.swift
//  TWQuote
//
//  Created by Fernando Bunn on 06/05/2019.
//  Copyright © 2019 Fernando Bunn. All rights reserved.
//

import Foundation

class MenuViewModel {
    
    let service: TWService
    init(service: TWService = TWService()) {
        self.service = service
    }
    
    private lazy var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        return numberFormatter
    }()
    
    
    func fetchQuote() async throws -> String? {
        let settings = SettingsModel.restore()
        numberFormatter.currencyCode = settings.targetCurrency.rawValue
        
        let response: String?
        if let payment = try await service.fetchQuote(sourceCurrency: settings.sourceCurrency, targetCurrency: settings.targetCurrency, amount: settings.amount).wiseQuote {
            response = self.numberFormatter.string(for: payment.receivedAmount)
        } else {
            response = nil
        }
        
        return response
    }
}
