// plasma.swift

enum PlasmaRange: Int, Sendable {
    case criticalAbundance = 1
    case elevated = 2
    case normalZone = 3
    case optimalZone = 4
    case deficient = 5
    case criticalDeficiency = 6
    
    var isCritical: Bool {
        self == .criticalAbundance || self == .criticalDeficiency
    }
    
    var isAbnormal: Bool {
        self == .elevated || self == .deficient
    }
    
    var isNormal: Bool {
        self == .normalZone || self == .optimalZone
    }
}

struct PlasmaValue: Sendable {
    let biomarkerId: Int
    let value: Double
    let range: PlasmaRange?
}

struct PlasmaOutput: Sendable {
    let message: String
    let importance: Int
    let ruleId: Int
}

struct PlasmaRule: Sendable {
    let id: Int
    let biomarkerIds: Set<Int>
    let evaluate: @Sendable ([PlasmaValue]) -> Bool
    let message: String
    let importance: Int
}

// Extended BiomarkerId enum
enum BiomarkerId {
    static let glucose = 1
    static let alt = 28  // alanine aminotransferase
    static let ast = 29  // aspartate aminotransferase
    static let hba1c = 33 // glycated hemoglobin
    static let ldlCholesterol = 2
    static let apoB = 3
    static let crp = 4
    static let insulin = 5
    static let calcium = 6
    static let vitaminD = 7
    static let cortisol = 8
    static let dheas = 9
    static let testosterone = 10
    static let magnesium = 11
    static let zinc = 12
    static let alkalinePhosphatase = 13
    static let ggt = 14
    static let hemoglobin = 15
    static let rbc = 16
    static let mcv = 17
    static let cholesterol = 18
    static let triglycerides = 19
    static let tsh = 20
    static let t4 = 21
    static let dDimer = 22
    static let biliTotal = 23
    static let biliDirect = 24
    static let biliIndirect = 25
    static let albumin = 26
    static let protein = 27
    static let pt = 30
    static let aptt = 31
    static let creatinine = 32
    static let egfr = 34
    static let prolactin = 35
    static let shbg = 36
}

final class PlasmaEngine {
    private let rules: [PlasmaRule]
    
    init(rules: [PlasmaRule]) {
        self.rules = rules
    }
    
    convenience init() {
        self.init(rules: [
            // Original Liver Function Rule
            PlasmaRule(
                id: 1,
                biomarkerIds: [BiomarkerId.alt, BiomarkerId.ast],
                evaluate: { values in
                    values.allSatisfy { value in
                        guard let range = value.range else { return false }
                        return range.isAbnormal || range.isCritical
                    }
                },
                message: "Your liver enzyme levels require attention. Consider lifestyle modifications and consult your healthcare provider.",
                importance: 3
            ),
            
            // Original Diabetes Rule
            PlasmaRule(
                id: 2,
                biomarkerIds: [BiomarkerId.glucose, BiomarkerId.hba1c],
                evaluate: { values in
                    values.contains { value in
                        guard let range = value.range else { return false }
                        return range.isCritical
                    }
                },
                message: "Your glucose levels indicate possible diabetes. Please consider lifestyle modifications and consult your healthcare provider for evaluation",
                importance: 3
            ),
            
            // Cardiovascular Risk Rule
            PlasmaRule(
                id: 3,
                biomarkerIds: [BiomarkerId.ldlCholesterol, BiomarkerId.apoB, BiomarkerId.crp],
                evaluate: { values in
                    let borderlineCount = values.filter { value in
                        guard let range = value.range else { return false }
                        return range == .elevated
                    }.count
                    return borderlineCount >= 2
                },
                message: "Consider coronary calcium scoring and carotid ultrasound for early atherosclerosis detection, even though values are only borderline elevated.",
                importance: 1
            ),
            
            // Metabolic Health Rule
            PlasmaRule(
                id: 4,
                biomarkerIds: [BiomarkerId.insulin, BiomarkerId.glucose, BiomarkerId.hba1c],
                evaluate: { values in
                    let criticalCount = values.filter { value in
                        guard let range = value.range else { return false }
                        return range.isCritical
                    }.count
                    let abnormalCount = values.filter { value in
                        guard let range = value.range else { return false }
                        return range.isAbnormal || range.isCritical
                    }.count
                    return criticalCount > 0 || abnormalCount >= 2
                },
                message: "Consider DEXA scan for detailed body composition analysis and visceral fat assessment.",
                importance: 1
            ),
            
            // Bone Health Rule
            PlasmaRule(
                id: 5,
                biomarkerIds: [BiomarkerId.calcium, BiomarkerId.vitaminD],
                evaluate: { values in
                    values.allSatisfy { value in
                        guard let range = value.range else { return false }
                        return range.isAbnormal || range.isCritical
                    }
                },
                message: "Consider DEXA scan for detailed body composition analysis and bone density.",
                importance: 1
            ),
            
            // Hormone Panel Rule
            PlasmaRule(
                id: 6,
                biomarkerIds: [BiomarkerId.cortisol, BiomarkerId.dheas, BiomarkerId.testosterone],
                evaluate: { values in
                    let criticalCount = values.filter { value in
                        guard let range = value.range else { return false }
                        return range.isCritical
                    }.count
                    if criticalCount > 0 { return true }
                    
                    let cortisolDheasAbnormal = values.filter { value in
                        guard let range = value.range else { return false }
                        return (value.biomarkerId == BiomarkerId.cortisol ||
                               value.biomarkerId == BiomarkerId.dheas) &&
                               (range.isAbnormal || range.isCritical)
                    }.count == 2
                    
                    return cortisolDheasAbnormal
                },
                message: "Consider 4-point salivary cortisol testing and comprehensive hormone panel.",
                importance: 1
            ),
            
            // Micronutrient Rule
            PlasmaRule(
                id: 7,
                biomarkerIds: [BiomarkerId.vitaminD, BiomarkerId.magnesium, BiomarkerId.zinc],
                evaluate: { values in
                    values.allSatisfy { value in
                        guard let range = value.range else { return false }
                        return range.isAbnormal || range.isCritical
                    }
                },
                message: "Consider comprehensive micronutrient testing including intracellular mineral analysis.",
                importance: 1
            ),
            
            // Extended Liver Health Rule
            PlasmaRule(
                id: 8,
                biomarkerIds: [BiomarkerId.alkalinePhosphatase, BiomarkerId.alt,
                              BiomarkerId.ggt, BiomarkerId.insulin],
                evaluate: { values in
                    let criticalCount = values.filter { value in
                        guard let range = value.range else { return false }
                        return range.isCritical
                    }.count
                    let abnormalCount = values.filter { value in
                        guard let range = value.range else { return false }
                        return range.isAbnormal || range.isCritical
                    }.count
                    return criticalCount > 0 || abnormalCount >= 2
                },
                message: "Consider liver elastography and abdominal ultrasound.",
                importance: 1
            ),
            
            // Anemia Rule
            PlasmaRule(
                id: 9,
                biomarkerIds: [BiomarkerId.hemoglobin, BiomarkerId.rbc, BiomarkerId.mcv],
                evaluate: { values in
                    let criticalCount = values.filter { value in
                        guard let range = value.range else { return false }
                        return range.isCritical
                    }.count
                    let abnormalCount = values.filter { value in
                        guard let range = value.range else { return false }
                        return range.isAbnormal || range.isCritical
                    }.count
                    return criticalCount > 0 || abnormalCount >= 2
                },
                message: "Your blood cell measurements indicate possible anemia. Please consult your healthcare provider.",
                importance: 3
            ),
            
            // Lipid Profile Rule
            PlasmaRule(
                id: 10,
                biomarkerIds: [BiomarkerId.cholesterol, BiomarkerId.ldlCholesterol,
                              BiomarkerId.triglycerides],
                evaluate: { values in
                    let criticalCount = values.filter { value in
                        guard let range = value.range else { return false }
                        return range.isCritical
                    }.count
                    let abnormalCount = values.filter { value in
                        guard let range = value.range else { return false }
                        return range.isAbnormal || range.isCritical
                    }.count
                    return criticalCount > 0 || abnormalCount >= 2
                },
                message: "Multiple components of your lipid profile show concerning values.",
                importance: 2
            ),
            
            // Thyroid Function Rule
            PlasmaRule(
                id: 11,
                biomarkerIds: [BiomarkerId.tsh, BiomarkerId.t4],
                evaluate: { values in
                    values.allSatisfy { value in
                        guard let range = value.range else { return false }
                        return range.isAbnormal || range.isCritical
                    }
                },
                message: "Your thyroid hormone levels require medical attention.",
                importance: 3
            ),
            
            // D-Dimer Rule
            PlasmaRule(
                id: 12,
                biomarkerIds: [BiomarkerId.dDimer],
                evaluate: { values in
                    values.allSatisfy { value in
                        guard let range = value.range else { return false }
                        return range.isAbnormal || range.isCritical
                    }
                },
                message: "Your coagulation markers require medical attention! This may indicate a risk of thrombosis!",
                importance: 3
            ),
            
            // Bilirubin Rule
            PlasmaRule(
                id: 13,
                biomarkerIds: [BiomarkerId.biliTotal, BiomarkerId.biliDirect,
                              BiomarkerId.biliIndirect, BiomarkerId.ggt],
                evaluate: { values in
                    values.allSatisfy { value in
                        guard let range = value.range else { return false }
                        return range.isAbnormal || range.isCritical
                    }
                },
                message: "Your liver enzyme levels require attention. Consider liver elastography.",
                importance: 3
            ),
            
            // Protein Rule
            PlasmaRule(
                id: 14,
                biomarkerIds: [BiomarkerId.albumin, BiomarkerId.protein],
                evaluate: { values in
                    values.allSatisfy { value in
                        guard let range = value.range else { return false }
                        return range.isAbnormal || range.isCritical
                    }
                },
                message: "Your liver function markers require medical attention!",
                importance: 3
            ),
            
            // Coagulation High Values Rule
            PlasmaRule(
                id: 15,
                biomarkerIds: [BiomarkerId.pt, BiomarkerId.aptt],
                evaluate: { values in
                    values.allSatisfy { value in
                        guard let range = value.range else { return false }
                        return range == .elevated || range == .criticalAbundance
                    }
                },
                message: "Your coagulation markers require medical attention! This may indicate a risk of bleeding!",
                importance: 3
            ),
            
            // Coagulation Low Values Rule
            PlasmaRule(
                id: 16,
                biomarkerIds: [BiomarkerId.pt, BiomarkerId.aptt],
                evaluate: { values in
                    values.allSatisfy { value in
                        guard let range = value.range else { return false }
                        return range == .deficient || range == .criticalDeficiency
                    }
                },
                message: "Your coagulation markers require medical attention! This may indicate a risk of thrombosis!",
                importance: 3
            ),
            
            // Kidney Function Rule
            PlasmaRule(
                id: 17,
                biomarkerIds: [BiomarkerId.creatinine, BiomarkerId.egfr],
                evaluate: { values in
                    values.allSatisfy { value in
                        guard let range = value.range else { return false }
                        return range.isAbnormal || range.isCritical
                    }
                },
                message: "Your kidney function markers require medical attention.",
                importance: 3
            ),
            
            // Hormone Interaction Rule
            PlasmaRule(
                id: 18,
                biomarkerIds: [BiomarkerId.testosterone, BiomarkerId.prolactin],
                evaluate: { values in
                    let testosteroneDeficient = values.first { $0.biomarkerId == BiomarkerId.testosterone }
                        .flatMap { value in
                            guard let range = value.range else { return false }
                            return range == .deficient || range == .criticalDeficiency
                        } ?? false
                    
                    let prolactinElevated = values.first { $0.biomarkerId == BiomarkerId.prolactin }
                        .flatMap { value in
                            guard let range = value.range else { return false }
                            return range == .elevated || range == .criticalAbundance
                        } ?? false
                    
                    return testosteroneDeficient && prolactinElevated
                },
                message: "Your hormone levels show an important interaction that requires medical evaluation.",
                importance: 3
            ),
            
            // SHBG Rule
            PlasmaRule(
                id: 19,
                biomarkerIds: [BiomarkerId.testosterone, BiomarkerId.shbg],
                evaluate: { values in
                    let criticalCount = values.filter { value in
                        guard let range = value.range else { return false }
                        return range.isCritical
                    }.count
                    let abnormalCount = values.filter { value in
                        guard let range = value.range else { return false }
                        return range.isAbnormal || range.isCritical
                    }.count
                    return criticalCount > 0 || abnormalCount > 0
                },
                message: "Your hormone and binding protein levels require attention.",
                importance: 2
            )
        ])
    }
    
    func process(_ values: [PlasmaValue]) -> [PlasmaOutput] {
        rules.compactMap { rule in
            let relevantValues = values.filter { rule.biomarkerIds.contains($0.biomarkerId) }
            guard relevantValues.count == rule.biomarkerIds.count else { return nil }
            
            return rule.evaluate(relevantValues) ?
                PlasmaOutput(
                    message: rule.message,
                    importance: rule.importance,
                    ruleId: rule.id
                ) : nil
        }
    }
}
