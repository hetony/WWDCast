//
//  FilterViewModel.swift
//  WWDCast
//
//  Created by Maksym Shcheglov on 14/08/2016.
//  Copyright © 2016 Maksym Shcheglov. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class FilterViewModel: FilterViewModelProtocol {

    private var filter: Filter
    private let completion: FilterViewModelCompletion
    private let disposeBag = DisposeBag()

    init(filter: Filter, completion: @escaping FilterViewModelCompletion) {
        self.filter = filter
        self.completion = completion
    }

    // MARK: SessionFilterViewModel

    let title = Driver.just(NSLocalizedString("Filter", comment: "Filter view title"))

    lazy var filterSections: Driver<[FilterSectionViewModel]> = {
        return Driver.just(self.filterViewModels())
    }()

    func didCancel() {
        self.completion(.cancelled)
    }

    func didApplyFilter() {
        self.completion(.finished(self.filter))
    }

    // MARK: Private

    private func filterViewModels() -> [FilterSectionViewModel] {
        return [yearsFilterViewModel(), platformsFilterViewModel(), eventTypeViewModel(), tracksFilterViewModel()]
    }

    private func yearsFilterViewModel() -> FilterSectionViewModel {
        var yearFilterItems = Session.Year.all.map { year in
            return FilterItemViewModel(title: year.description, style: .checkmark, selected: self.filter.years == [year])
        }
        yearFilterItems.insert(FilterItemViewModel(title: NSLocalizedString("All years", comment: ""), style: .checkmark, selected: self.filter.years == Session.Year.all), at: 0)

        let years = FilterSectionViewModel(type: .Years, items: yearFilterItems)
        years.selection.filter({ _, selected in
            return selected
        }).do(onNext: { index, _ in
            years.selectItem(atIndex: index)
        }).flatMap(self.yearsSelection(years)).distinctUntilChanged(==).subscribe(onNext: { years in
            self.filter.years = years
            NSLog("%@", self.filter.description)
        }).addDisposableTo(self.disposeBag)

        return years
    }

    private func eventTypeViewModel() -> FilterSectionViewModel {
        var eventTypeItems = Session.EventType.all.map { eventType in
            return FilterItemViewModel(title: eventType.description, style: .checkmark, selected: self.filter.eventTypes == [eventType])
        }
        eventTypeItems.insert(FilterItemViewModel(title: NSLocalizedString("All Events", comment: ""), style: .checkmark, selected: self.filter.eventTypes == Session.EventType.all), at: 0)

        let eventTypes = FilterSectionViewModel(type: .EventTypes, items: eventTypeItems)
        eventTypes.selection.filter({ _, selected in
            return selected
        }).do(onNext: { index, _ in
            eventTypes.selectItem(atIndex: index)
        }).flatMap(self.eventTypesSelection(eventTypes)).distinctUntilChanged(==).subscribe(onNext: { eventTypes in
            self.filter.eventTypes = eventTypes
            NSLog("%@", self.filter.description)
        }).addDisposableTo(self.disposeBag)

        return eventTypes
    }

    private func platformsFilterViewModel() -> FilterSectionViewModel {
        var platformFilterItems = Session.Platform.all.map { platform in
            return FilterItemViewModel(title: platform.description, style: .checkmark, selected: self.filter.platforms == [platform])
        }
        platformFilterItems.insert(FilterItemViewModel(title: NSLocalizedString("All platforms", comment: ""), style: .checkmark, selected: self.filter.platforms == Session.Platform.all), at: 0)

        let platforms = FilterSectionViewModel(type: .Platforms, items: platformFilterItems)
        platforms.selection.filter({ _, selected in
            return selected
        }).do(onNext: { index, _ in
            platforms.selectItem(atIndex: index)
        }).map(self.platformsSelection(platforms)).distinctUntilChanged(==).subscribe(onNext: {[unowned self] platforms in
            self.filter.platforms = platforms
            NSLog("%@", self.filter.description)
        }).addDisposableTo(self.disposeBag)

        return platforms
    }

    private func tracksFilterViewModel() -> FilterSectionViewModel {
        let trackFilterItems = Session.Track.all.map { track in
            return FilterItemViewModel(title: track.description, style: .switch, selected: self.filter.tracks.contains(track))
        }

        let tracks = FilterSectionViewModel(type: .Tracks, items: trackFilterItems)
        tracks.selection.map({ index, selected -> [Session.Track] in
            var tracks = self.filter.tracks
            guard let track = Session.Track(rawValue: index) else {
                return tracks
            }
            if selected {
                if tracks.index(of: track) == nil {
                    tracks.append(track)
                }
            } else if let index = tracks.index(of: track) {
                tracks.remove(at: index)
            }
            return tracks
        }).distinctUntilChanged(==).subscribe(onNext: {[unowned self] tracks in
            self.filter.tracks = tracks
            NSLog("%@", self.filter.description)
        }).addDisposableTo(self.disposeBag)

        return tracks
    }

    private func yearsSelection(_ years: FilterSectionViewModel) -> (Int, Bool) -> Observable<[Session.Year]> {
        return { (idx, _) in
            if idx == 0 {
                return Observable.just(Session.Year.all)
            }
            let selectedYear = Session.Year.all[idx - 1]
            return Observable.just([selectedYear])
        }
    }

    private func eventTypesSelection(_ eventTypes: FilterSectionViewModel) -> (Int, Bool) -> Observable<[Session.EventType]> {
        return { (idx, _) in
            if idx == 0 {
                return Observable.just(Session.EventType.all)
            }
            let selectedEventType = Session.EventType.all[idx - 1]
            return Observable.just([selectedEventType])
        }
    }

    private func platformsSelection(_ platforms: FilterSectionViewModel) -> (Int, Bool) -> Session.Platform {
        return { (idx, _) in
            if idx == 0 {
                return Session.Platform.all
            }
            return Session.Platform(rawValue: 1 << (idx - 1))
        }
    }

}
