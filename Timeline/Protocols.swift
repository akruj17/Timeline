//
//  Protocols.swift
//  Timeline
//
//  Created by Arjun Kunjilwar on 12/20/18.
//  Copyright © 2018 Edumacation!. All rights reserved.
//

import UIKit

// communication protocol for EventEditorCell -> TimelineEditorVC && EventDetailedView -> TimelineVC
protocol EditorDataSaveDelegate: class {
    func saveTitle (title: String)
    func saveOverview (overview: String, index: Int)
    func saveDetailed (detailed: String, index: Int)
    func saveTimePeriod (isTimePeriod: Bool, index: Int)
    func saveYear (year: Int?, index: Int)
    func saveEndYear (year: Int?, index: Int)
    func setActiveTextField(textField: UIView) //any because it could be a text field or text view
}

// communication protocol for (TimelineEditorVC && TimelineVC) -> TitleScreenVC
protocol CollectionReloadDelegate: class {
    func updateCollection(completion: ((Bool) -> ())?)
}

// communication protocol for TitleScrnLayout -> TitleScreenVC
protocol TitleCollectionDelegate: class {
    func updateCollectionWidth(newWidth: CGFloat)
}

// communication protocol for TimelineLayout -> TimelineVC
protocol TimelineCollectionDelegate: class {
    func getWidthAtIndexPath(index: Int) -> CGFloat
}

// communication protocol for BackgroundModifierVC -> TimelineVC
protocol BackgroundModifierDelegate: class {
    func backgroundModifierDonePressed(updateAt updateIndex: Int)
}
