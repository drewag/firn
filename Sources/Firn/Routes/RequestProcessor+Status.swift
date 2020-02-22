//
//  File.swift
//  
//
//  Created by Andrew J Wagner on 2/19/20.
//

import NIOHTTP1

extension RequestProcessor {
    public func status(_ status: HTTPResponseStatus) -> RequestProcessor<Input, Output> {
        return RequestProcessor(
            helper: self._routingHelper,
            before: self,
            newStatus: status
        )
    }
}
