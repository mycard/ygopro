#include "deck_manager.h"
#include "myfilesystem.h"
#include "data_manager.h"
#include "network.h"
#include "game.h"
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <iostream>
#include <algorithm> // For std::shuffle, std::copy_if
#include <vector>
#include <random>
#include <unordered_set>

namespace ygo {

#ifndef YGOPRO_SERVER_MODE
char DeckManager::deckBuffer[0x10000]{};
#endif
DeckManager deckManager;

void DeckManager::LoadLFListSingle(const char* path) {
	auto cur = _lfList.rend();
	FILE* fp = fopen(path, "r");
	char linebuf[256]{};
	wchar_t strBuffer[256]{};
	if(fp) {
		while(fgets(linebuf, 256, fp)) {
			if(linebuf[0] == '#')
				continue;
			if(linebuf[0] == '!') {
				int sa = BufferIO::DecodeUTF8(&linebuf[1], strBuffer);
				while(strBuffer[sa - 1] == L'\r' || strBuffer[sa - 1] == L'\n' )
					sa--;
				strBuffer[sa] = 0;
				LFList newlist;
				_lfList.push_back(newlist);
				cur = _lfList.rbegin();
				cur->listName = strBuffer;
				cur->hash = 0x7dfcee6a;
				continue;
			}
			if(linebuf[0] == 0)
				continue;
			int code = 0;
			int count = -1;
			if (sscanf(linebuf, "%d %d", &code, &count) != 2)
				continue;
			if (code <= 0 || code > 0xfffffff)
				continue;
			if (count < 0 || count > 2)
				continue;
			if (cur == _lfList.rend())
				continue;
			unsigned int hcode = code;
			cur->content[code] = count;
			cur->hash = cur->hash ^ ((hcode << 18) | (hcode >> 14)) ^ ((hcode << (27 + count)) | (hcode >> (5 - count)));
		}
		fclose(fp);
	}
}
void DeckManager::LoadLFList() {
#ifdef SERVER_PRO2_SUPPORT
	LoadLFListSingle("config/lflist.conf");
#endif
	LoadLFListSingle("expansions/lflist.conf");
	LoadLFListSingle("lflist.conf");
	LFList nolimit;
	nolimit.listName = L"N/A";
	nolimit.hash = 0;
	_lfList.push_back(nolimit);
}
const wchar_t* DeckManager::GetLFListName(int lfhash) {
	auto lit = std::find_if(_lfList.begin(), _lfList.end(), [lfhash](const ygo::LFList& list) {
		return list.hash == lfhash;
	});
	if(lit != _lfList.end())
		return lit->listName.c_str();
	return dataManager.unknown_string;
}
const std::unordered_map<int, int>* DeckManager::GetLFListContent(int lfhash) {
	auto lit = std::find_if(_lfList.begin(), _lfList.end(), [lfhash](const ygo::LFList& list) {
		return list.hash == lfhash;
	});
	if(lit != _lfList.end())
		return &lit->content;
	return nullptr;
}
static int checkAvail(unsigned int ot, unsigned int avail) {
	if((ot & avail) == avail)
		return 0;
	if((ot & AVAIL_OCG) && !(avail == AVAIL_OCG))
		return DECKERROR_OCGONLY;
	if((ot & AVAIL_TCG) && !(avail == AVAIL_TCG))
		return DECKERROR_TCGONLY;
	return DECKERROR_NOTAVAIL;
}
int DeckManager::CheckDeck(Deck& deck, int lfhash, int rule) {
	std::unordered_map<int, int> ccount;
	auto list = GetLFListContent(lfhash);
	if(!list)
		return 0;
	int dc = 0;
	// if(deck.main.size() < 40 || deck.main.size() > 60)
	// 	return (DECKERROR_MAINCOUNT << 28) + deck.main.size();
	// if(deck.extra.size() > 15)
	// 	return (DECKERROR_EXTRACOUNT << 28) + deck.extra.size();
	if(deck.side.size() > 15)
		return (DECKERROR_SIDECOUNT << 28) + deck.side.size();
	const int rule_map[6] = { AVAIL_OCG, AVAIL_TCG, AVAIL_SC, AVAIL_CUSTOM, AVAIL_OCGTCG, 0 };
	int avail = rule_map[rule];
	for(size_t i = 0; i < deck.main.size(); ++i) {
		code_pointer cit = deck.main[i];
		int gameruleDeckError = checkAvail(cit->second.ot, avail);
		if(gameruleDeckError)
			return (gameruleDeckError << 28) + cit->first;
		if (cit->second.type & (TYPES_EXTRA_DECK | TYPE_TOKEN))
			return (DECKERROR_EXTRACOUNT << 28);
		int code = cit->second.alias ? cit->second.alias : cit->first;
		ccount[code]++;
		dc = ccount[code];
		if(dc > 3)
			return (DECKERROR_CARDCOUNT << 28) + cit->first;
		auto it = list->find(code);
		if(it != list->end() && dc > it->second)
			return (DECKERROR_LFLIST << 28) + cit->first;
	}
	for (auto& cit : deck.extra) {
		int gameruleDeckError = checkAvail(cit->second.ot, avail);
		if(gameruleDeckError)
			return (gameruleDeckError << 28) + cit->first;
		int code = cit->second.alias ? cit->second.alias : cit->first;
		ccount[code]++;
		dc = ccount[code];
		if(dc > 3)
			return (DECKERROR_CARDCOUNT << 28) + cit->first;
		auto it = list->find(code);
		if(it != list->end() && dc > it->second)
			return (DECKERROR_LFLIST << 28) + cit->first;
	}
	for (auto& cit : deck.side) {
		int gameruleDeckError = checkAvail(cit->second.ot, avail);
		if(gameruleDeckError)
			return (gameruleDeckError << 28) + cit->first;
		int code = cit->second.alias ? cit->second.alias : cit->first;
		ccount[code]++;
		dc = ccount[code];
		if(dc > 3)
			return (DECKERROR_CARDCOUNT << 28) + cit->first;
		auto it = list->find(code);
		if(it != list->end() && dc > it->second)
			return (DECKERROR_LFLIST << 28) + cit->first;
	}
	return 0;
}
int DeckManager::LoadDeck(Deck& deck, int* dbuf, int mainc, int sidec, bool is_packlist) {
	auto &allCardsData = dataManager.GetAllCardsData(); // 获取所有卡片数据
	std::vector<unsigned int> mainCodes, extraCodes;

	std::unordered_set<unsigned int> banlist;
	std::ifstream banlistfile("Iflist.txt");
	unsigned int code;
	while (banlistfile >> code)
	{
		banlist.insert(code);
	}

	// 筛选卡片代码
	for (const auto &card : allCardsData)
	{
		if (!(card.second.type & TYPE_TOKEN) && banlist.find(card.first) == banlist.end())
		{ // 排除Token类型和禁止的卡
			if (card.second.type & (TYPE_FUSION | TYPE_SYNCHRO | TYPE_XYZ | TYPE_LINK))
			{
				extraCodes.push_back(card.first); // 适合额外卡组的卡
			}
			else
			{
				mainCodes.push_back(card.first); // 适合主卡组和副卡组的卡
			}
		}
	}

	// 随机选择卡片
	std::random_device rd;
	std::mt19937 g(rd());
	std::shuffle(mainCodes.begin(), mainCodes.end(), g);
	std::shuffle(extraCodes.begin(), extraCodes.end(), g);

	// 为了简化，我们将副卡组也从mainCodes中选择
	std::vector<unsigned int> sideCodes(mainCodes.begin(), mainCodes.end());

	// 选择卡片数量
	int mainDeckSize = std::min(60, static_cast<int>(mainCodes.size()));
	int extraDeckSize = std::min(30, static_cast<int>(extraCodes.size()));
	int sideDeckSize = std::min(0, static_cast<int>(sideCodes.size()));

	deck.clear();
	int errorcode = 0;

	// 加载主卡组
	for (int i = 0; i < mainDeckSize; ++i)
	{
		auto code = mainCodes[i];
		CardData cd;
		if (!dataManager.GetData(code, &cd))
		{
			errorcode = code;
			continue;
		}
		deck.main.push_back(dataManager.GetCodePointer(code));
	}

	// 加载额外卡组
	for (int i = 0; i < extraDeckSize; ++i)
	{
		auto code = extraCodes[i];
		CardData cd;
		if (!dataManager.GetData(code, &cd))
		{
			errorcode = code;
			continue;
		}
		deck.extra.push_back(dataManager.GetCodePointer(code));
	}

	// 加载副卡组
	for (int i = 0; i < sideDeckSize; ++i)
	{
		auto code = sideCodes[i];
		CardData cd;
		if (!dataManager.GetData(code, &cd))
		{
			errorcode = code;
			continue;
		}
		deck.side.push_back(dataManager.GetCodePointer(code));
	}

	// 加入规则卡
	std::string filePath = "./ruleCardList.txt"; // 指定文件路径
	std::ifstream file(filePath);
	std::string line;

	if (file.is_open())
	{
		// 读取文件中的每一行
		while (std::getline(file, line))
		{
			std::istringstream iss(line);
			std::string part;
			std::vector<long> numbers;

			// 假设数字之间以空格分隔
			while (std::getline(iss, part, ' '))
			{
				try
				{
					long number = std::stol(part);
					numbers.push_back(number);
				}
				catch (std::invalid_argument &e)
				{
					std::cerr << "Conversion error: " << e.what() << '\n';
				}
				catch (std::out_of_range &e)
				{
					std::cerr << "Number out of range: " << e.what() << '\n';
				}
			}

			// 输出转换后的数字
			for (long num : numbers)
			{
				deck.main.push_back(dataManager.GetCodePointer(num));
			}
		}
	}

	return errorcode;
}
int DeckManager::LoadDeck(Deck& deck, std::istringstream& deckStream, bool is_packlist) {
	int ct = 0, mainc = 0, sidec = 0, code = 0;
	int cardlist[300]{};
	bool is_side = false;
	std::string linebuf;
	while (std::getline(deckStream, linebuf, '\n') && ct < (int)(sizeof cardlist / sizeof cardlist[0])) {
		if (linebuf[0] == '!') {
			is_side = true;
			continue;
		}
		if (linebuf[0] < '0' || linebuf[0] > '9')
			continue;
		code = std::stoi(linebuf);
		cardlist[ct++] = code;
		if (is_side)
			++sidec;
		else
			++mainc;
	}
	return LoadDeck(current_deck, cardlist, mainc, sidec, is_packlist);
}
bool DeckManager::LoadSide(Deck& deck, int* dbuf, int mainc, int sidec) {
	std::unordered_map<int, int> pcount;
	std::unordered_map<int, int> ncount;
	for(size_t i = 0; i < deck.main.size(); ++i)
		++pcount[deck.main[i]->first];
	for(size_t i = 0; i < deck.extra.size(); ++i)
		++pcount[deck.extra[i]->first];
	for(size_t i = 0; i < deck.side.size(); ++i)
		++pcount[deck.side[i]->first];
	Deck ndeck;
	LoadDeck(ndeck, dbuf, mainc, sidec);
	// if(ndeck.main.size() != deck.main.size() || ndeck.extra.size() != deck.extra.size())
	// 	return false;
	// for(size_t i = 0; i < ndeck.main.size(); ++i)
	// 	ncount[ndeck.main[i]->first]++;
	// for(size_t i = 0; i < ndeck.extra.size(); ++i)
	// 	ncount[ndeck.extra[i]->first]++;
	// for(size_t i = 0; i < ndeck.side.size(); ++i)
	// 	ncount[ndeck.side[i]->first]++;
	// for(auto cdit = ncount.begin(); cdit != ncount.end(); ++cdit)
	// 	if(cdit->second != pcount[cdit->first])
	// 		return false;
	deck = ndeck;
	return true;
}
#ifndef YGOPRO_SERVER_MODE
void DeckManager::GetCategoryPath(wchar_t* ret, int index, const wchar_t* text) {
	wchar_t catepath[256];
	switch(index) {
	case 0:
		myswprintf(catepath, L"./pack");
		break;
	case 1:
		myswprintf(catepath, mainGame->gameConf.bot_deck_path);
		break;
	case -1:
	case 2:
	case 3:
		myswprintf(catepath, L"./deck");
		break;
	default:
		myswprintf(catepath, L"./deck/%ls", text);
	}
	BufferIO::CopyWStr(catepath, ret, 256);
}
void DeckManager::GetDeckFile(wchar_t* ret, irr::gui::IGUIComboBox* cbCategory, irr::gui::IGUIComboBox* cbDeck) {
	wchar_t filepath[256];
	wchar_t catepath[256];
	const wchar_t* deckname = cbDeck->getItem(cbDeck->getSelected());
	if(deckname != NULL) {
		GetCategoryPath(catepath, cbCategory->getSelected(), cbCategory->getText());
		myswprintf(filepath, L"%ls/%ls.ydk", catepath, deckname);
		BufferIO::CopyWStr(filepath, ret, 256);
	}
	else {
		BufferIO::CopyWStr(L"", ret, 256);
	}
}
FILE* DeckManager::OpenDeckFile(const wchar_t* file, const char* mode) {
	char fullname[256]{};
	BufferIO::EncodeUTF8(file, fullname);
	FILE* fp = myfopen(fullname, mode);
	return fp;
}
IReadFile* DeckManager::OpenDeckReader(const wchar_t* file) {
#ifdef WIN32
	IReadFile* reader = dataManager.FileSystem->createAndOpenFile(file);
#else
	char file2[256];
	BufferIO::EncodeUTF8(file, file2);
	IReadFile* reader = dataManager.FileSystem->createAndOpenFile(file2);
#endif
	return reader;
}
bool DeckManager::LoadCurrentDeck(const wchar_t* file, bool is_packlist) {
	current_deck.clear();
	IReadFile* reader = OpenDeckReader(file);
	if(!reader) {
		wchar_t localfile[64];
		myswprintf(localfile, L"./deck/%ls.ydk", file);
		reader = OpenDeckReader(localfile);
	}
	if(!reader && !mywcsncasecmp(file, L"./pack", 6)) {
		wchar_t zipfile[64];
		myswprintf(zipfile, L"%ls", file + 2);
		reader = OpenDeckReader(zipfile);
	}
	if(!reader)
		return false;
	auto size = reader->getSize();
	if(size >= (int)sizeof deckBuffer) {
		reader->drop();
		return false;
	}
	std::memset(deckBuffer, 0, sizeof deckBuffer);
	reader->read(deckBuffer, size);
	reader->drop();
	std::istringstream deckStream(deckBuffer);
	LoadDeck(current_deck, deckStream, is_packlist);
	return true;  // the above LoadDeck has return value but we ignore it here for now
}
bool DeckManager::LoadCurrentDeck(irr::gui::IGUIComboBox* cbCategory, irr::gui::IGUIComboBox* cbDeck) {
	wchar_t filepath[256];
	GetDeckFile(filepath, cbCategory, cbDeck);
	bool is_packlist = cbCategory->getSelected() == 0;
	bool res = LoadCurrentDeck(filepath, is_packlist);
	if (res && mainGame->is_building)
		mainGame->deckBuilder.RefreshPackListScroll();
	return res;
}
bool DeckManager::SaveDeck(Deck& deck, const wchar_t* file) {
	if(!FileSystem::IsDirExists(L"./deck") && !FileSystem::MakeDir(L"./deck"))
		return false;
	FILE* fp = OpenDeckFile(file, "w");
	if(!fp)
		return false;
	fprintf(fp, "#created by ...\n#main\n");
	for(size_t i = 0; i < deck.main.size(); ++i)
		fprintf(fp, "%d\n", deck.main[i]->first);
	fprintf(fp, "#extra\n");
	for(size_t i = 0; i < deck.extra.size(); ++i)
		fprintf(fp, "%d\n", deck.extra[i]->first);
	fprintf(fp, "!side\n");
	for(size_t i = 0; i < deck.side.size(); ++i)
		fprintf(fp, "%d\n", deck.side[i]->first);
	fclose(fp);
	return true;
}
bool DeckManager::DeleteDeck(const wchar_t* file) {
#ifdef WIN32
	BOOL result = DeleteFileW(file);
	return !!result;
#else
	char filefn[256];
	BufferIO::EncodeUTF8(file, filefn);
	int result = unlink(filefn);
	return result == 0;
#endif
}
bool DeckManager::CreateCategory(const wchar_t* name) {
	if(!FileSystem::IsDirExists(L"./deck") && !FileSystem::MakeDir(L"./deck"))
		return false;
	if(name[0] == 0)
		return false;
	wchar_t localname[256];
	myswprintf(localname, L"./deck/%ls", name);
	return FileSystem::MakeDir(localname);
}
bool DeckManager::RenameCategory(const wchar_t* oldname, const wchar_t* newname) {
	if(!FileSystem::IsDirExists(L"./deck") && !FileSystem::MakeDir(L"./deck"))
		return false;
	if(newname[0] == 0)
		return false;
	wchar_t oldlocalname[256];
	wchar_t newlocalname[256];
	myswprintf(oldlocalname, L"./deck/%ls", oldname);
	myswprintf(newlocalname, L"./deck/%ls", newname);
	return FileSystem::Rename(oldlocalname, newlocalname);
}
bool DeckManager::DeleteCategory(const wchar_t* name) {
	wchar_t localname[256];
	myswprintf(localname, L"./deck/%ls", name);
	if(!FileSystem::IsDirExists(localname))
		return false;
	return FileSystem::DeleteDir(localname);
}
bool DeckManager::SaveDeckBuffer(const int deckbuf[], const wchar_t* name) {
	if (!FileSystem::IsDirExists(L"./deck") && !FileSystem::MakeDir(L"./deck"))
		return false;
	FILE* fp = OpenDeckFile(name, "w");
	if (!fp)
		return false;
	int it = 0;
	const int mainc = deckbuf[it];
	++it;
	fprintf(fp, "#created by ...\n#main\n");
	for (int i = 0; i < mainc; ++i) {
		fprintf(fp, "%d\n", deckbuf[it]);
		++it;
	}
	const int extrac = deckbuf[it];
	++it;
	fprintf(fp, "#extra\n");
	for (int i = 0; i < extrac; ++i) {
		fprintf(fp, "%d\n", deckbuf[it]);
		++it;
	}
	const int sidec = deckbuf[it];
	++it;
	fprintf(fp, "!side\n");
	for (int i = 0; i < sidec; ++i) {
		fprintf(fp, "%d\n", deckbuf[it]);
		++it;
	}
	fclose(fp);
	return true;
}
#endif //YGOPRO_SERVER_MODE
}
