//
//  CharactersListView.swift
//  RickAndMorty
//
//  Created by Luis Ezcurdia on 15/12/23.
//

import SwiftUI
import Combine

class CharactersListVM: ObservableObject {
    @Published var characters: [Character] = []
    @Published var currentPage: Int = 1

    private let client = RESTClient<PaginatedResponse<Character>>(client: Client.rickAndMorty)

    private var cancelableSet: Set<AnyCancellable> = []

    init() {
        client
            .showPublisher(path: "/api/character", page: currentPage)
            .receive(on: RunLoop.main)
            .sink { _ in
                print("Did complete loading")
            } receiveValue: { response in
                let results = response?.results ?? []
                self.characters.append(contentsOf: results)
            }
            .store(in: &cancelableSet)
    }

    func loadNextPage() {
        currentPage += 1
        print("It should load with combine")
    }
}

struct CharactersListView: View {
    let vm = CharactersListVM()

    var body: some View {
        NavigationView {
            List(vm.characters) { character in
                CharacterRow(character: character)
                    .onAppear {
                        if character == vm.characters.last {
                            vm.loadNextPage()
                        }
                    }
            }
            .listStyle(.plain)
            .navigationTitle("Characters")
        }
    }
}

#Preview {
    CharactersListView()
}
