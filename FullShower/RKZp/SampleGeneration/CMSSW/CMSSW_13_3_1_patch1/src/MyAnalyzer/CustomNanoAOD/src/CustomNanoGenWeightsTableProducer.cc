#include <memory>
#include <string>
#include <vector>

#include "DataFormats/NanoAOD/interface/FlatTable.h"
#include "FWCore/Framework/interface/Event.h"
#include "FWCore/Framework/interface/MakerMacros.h"
#include "FWCore/Framework/interface/global/EDProducer.h"
#include "FWCore/ParameterSet/interface/ConfigurationDescriptions.h"
#include "FWCore/ParameterSet/interface/ParameterSet.h"
#include "FWCore/ParameterSet/interface/ParameterSetDescription.h"
#include "FWCore/Utilities/interface/Exception.h"
#include "FWCore/Utilities/interface/InputTag.h"
#include "FWCore/Utilities/interface/StreamID.h"
#include "SimDataFormats/GeneratorProducts/interface/GenEventInfoProduct.h"

class CustomNanoGenWeightsTableProducer : public edm::global::EDProducer<> {
public:
  explicit CustomNanoGenWeightsTableProducer(const edm::ParameterSet& cfg)
      : genToken_(consumes<GenEventInfoProduct>(cfg.getParameter<edm::InputTag>("genEvent"))),
        scaleIndices_(cfg.getParameter<std::vector<unsigned int>>("scaleIndices")),
        pdfIndices_(cfg.getParameter<std::vector<unsigned int>>("pdfIndices")),
        precision_(cfg.getParameter<int>("precision")),
        normalizeToNominal_(cfg.getParameter<bool>("normalizeToNominal")),
        prependPdfOne_(cfg.getParameter<bool>("prependPdfOne")) {
    produces<nanoaod::FlatTable>();
    produces<nanoaod::FlatTable>("LHEScale");
    produces<nanoaod::FlatTable>("LHEPdf");
  }

  void produce(edm::StreamID, edm::Event& event, const edm::EventSetup&) const override {
    const auto& genInfo = event.get(genToken_);
    const auto& weights = genInfo.weights();

    if (weights.empty()) {
      throw cms::Exception("CustomNanoGenWeightsTableProducer") << "GenEventInfoProduct has no weights";
    }

    const double nominal = normalizeToNominal_ ? weights.at(1) : 1.0;
    if (nominal == 0.0) {
      throw cms::Exception("CustomNanoGenWeightsTableProducer") << "Nominal generator weight at index 1 is zero";
    }

    auto genWeightTable = std::make_unique<nanoaod::FlatTable>(1, "genWeight", true);
    genWeightTable->setDoc("generator weight");
    genWeightTable->addColumnValue<float>("", genInfo.weight(), "generator weight");
    event.put(std::move(genWeightTable));

    auto scaleWeights = selectedWeights(weights, scaleIndices_, nominal);
    auto scaleTable = std::make_unique<nanoaod::FlatTable>(scaleWeights.size(), "LHEScaleWeight", false);
    scaleTable->addColumn<float>(
        "", scaleWeights, "Selected generator weights saved as LHEScaleWeight (w_var / w_nominal)", precision_);
    event.put(std::move(scaleTable), "LHEScale");

    std::vector<double> pdfWeights;
    if (prependPdfOne_) {
      pdfWeights.push_back(1.0);
    }
    const auto selectedPdfWeights = selectedWeights(weights, pdfIndices_, nominal);
    pdfWeights.insert(pdfWeights.end(), selectedPdfWeights.begin(), selectedPdfWeights.end());

    auto pdfTable = std::make_unique<nanoaod::FlatTable>(pdfWeights.size(), "LHEPdfWeight", false);
    pdfTable->addColumn<float>(
        "", pdfWeights, "Selected generator weights saved as LHEPdfWeight (w_var / w_nominal)", precision_);
    event.put(std::move(pdfTable), "LHEPdf");
  }

  static void fillDescriptions(edm::ConfigurationDescriptions& descriptions) {
    edm::ParameterSetDescription desc;
    desc.add<edm::InputTag>("genEvent");
    desc.add<std::vector<unsigned int>>("scaleIndices");
    desc.add<std::vector<unsigned int>>("pdfIndices");
    desc.add<int>("precision", 14);
    desc.add<bool>("normalizeToNominal", true);
    desc.add<bool>("prependPdfOne", true);
    descriptions.add("customNanoGenWeightsTable", desc);
  }

private:
  static std::vector<double> selectedWeights(const std::vector<double>& weights,
                                             const std::vector<unsigned int>& indices,
                                             double nominal) {
    std::vector<double> out;
    out.reserve(indices.size());
    for (const auto index : indices) {
      if (index >= weights.size()) {
        throw cms::Exception("CustomNanoGenWeightsTableProducer")
            << "Requested generator weight index " << index << ", but only " << weights.size() << " weights are present";
      }
      out.push_back(weights.at(index) / nominal);
    }
    return out;
  }

  const edm::EDGetTokenT<GenEventInfoProduct> genToken_;
  const std::vector<unsigned int> scaleIndices_;
  const std::vector<unsigned int> pdfIndices_;
  const int precision_;
  const bool normalizeToNominal_;
  const bool prependPdfOne_;
};

DEFINE_FWK_MODULE(CustomNanoGenWeightsTableProducer);
