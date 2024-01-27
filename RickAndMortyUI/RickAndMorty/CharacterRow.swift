import SwiftUI
import CachedAsyncImage

struct CharacterRow: View {
    let character: Character
    var body: some View {
        HStack {
            CachedAsyncImage(url: character.imageURL()) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 8, height: 8)))
            } placeholder: {
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: 72, height: 72)
                    .foregroundColor(.secondary)

            }
            VStack(alignment: .leading) {
                Text(character.name)
                    .font(.headline)
                Text(character.species)
                    .font(.subheadline)
            }
            Spacer()
        }
    }
}

#Preview {
    CharacterRow(character: Character(id: 1, name: "Rick Sanchez", species: "Human", image: "https://rickandmortyapi.com/api/character/avatar/1.jpeg"))
}
