import Foundation

/// Fetches satellite status reports from the AMSAT Oscar Satellite Status API.
///
/// AMSAT operators submit health reports about amateur satellites. This service
/// maps NORAD catalog IDs to AMSAT satellite names and fetches recent status reports.
/// Source: https://www.amsat.org/status/
actor AMSATStatusService {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Public API
    
    /// Fetch recent status reports for a satellite by its NORAD catalog ID.
    /// - Parameters:
    ///   - forNoradID: The satellite's NORAD catalog ID (e.g., "25544" for ISS)
    ///   - hours: Number of hours of history to fetch (default 24)
    /// - Returns: Array of status reports, or empty array if satellite not in AMSAT database
    func fetchReports(forNoradID noradID: String, hours: Int = Constants.AMSAT.defaultHours) async -> [AMSATStatusReport] {
        guard let amsatName = Self.amsatNameMapping[noradID] else {
            return []
        }
        
        return await fetchReportsFromAPI(amsatName: amsatName, hours: hours)
    }
    
    /// Check if a satellite has an AMSAT name mapping (determines if status reports are available).
    static func hasAMSATName(for noradID: String) -> Bool {
        amsatNameMapping[noradID] != nil
    }
    
    // MARK: - Private Implementation
    
    /// Fetch status reports by AMSAT satellite name.
    private func fetchReportsFromAPI(amsatName: String, hours: Int) async -> [AMSATStatusReport] {
        guard var components = URLComponents(string: Constants.AMSAT.statusAPIBase) else {
            return []
        }
        
        components.queryItems = [
            URLQueryItem(name: "name", value: amsatName),
            URLQueryItem(name: "hours", value: String(hours))
        ]
        
        guard let url = components.url else {
            return []
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return []
            }
            
            let decoder = JSONDecoder()
            let reports = try decoder.decode([AMSATStatusReport].self, from: data)
            return reports
        } catch {
            // Return empty array on any error (unreachable API, decode failure, etc.)
            // ViewModel handles when to show "no reports" vs. errors
            return []
        }
    }
    
    // MARK: - NORAD ID → AMSAT Name Mapping
    
    /// Maps NORAD catalog IDs to AMSAT satellite names.
    ///
    /// Valid AMSAT names (as of 2026-04-23, from status page dropdown):
    /// AO-123_[FM], AO-123_[SSTV], AO-7_[U/v], AO-7_[V/a], AO-73_[U/v], AO-91_[FM],
    /// ArcticSat-1_[SSTV], BALKAN-1_[Music], CAS-3H_[FM], CatSat_[C/x], CroCube_[UHF_Digi],
    /// EMISAR_[Music], Flamingo-1_[Music], FO-29_[V/u], Foresail-1p_[UHF_Digi],
    /// GRBBeta_[UHF_Digi], GRBBeta_[VHF_Digi], HADES-SA_[CODEC2], HADES-SA_[FSK],
    /// HADES-SA_[SSDV], HC1PX_[SSTV], INCA-2_[V/u_Digi], IO-86_[FM], IO-86_[SSDV],
    /// IO-86_[VHF_Digi], ISS_[Crew], ISS_[DATV], ISS_[FM], ISS_[SSTV], ISS_[UHF_Digi],
    /// ISS_[VHF_Digi], JO-97_[U/v], KNACKSAT-2_[VHF_Digi], LASARsat_[UHF_Digi],
    /// LILIUM-4_[VHF_Digi], Luca_[SSDV], NO-44_[VHF_Digi], OPTISAT_[Music], OTP-2_[Music],
    /// Out_of_the_Box_[Music], PARUS-6U1_[VHF_Digi], PO-101_[FM], QO-100_[NB], QO-100_[WB],
    /// RS-44_[V/u], RS18S_[SSTV], RS38S_[SSTV], RS40S_[SSTV], RS49S_[SSTV], RS57S_[SSTV],
    /// RS58S_[SSDV], RS59S_[SSDV], RS61S_[SSDV], RS66S_[SSDV], RS74S_[SSTV], RS83S_[FM],
    /// RS83S_[SSDV], RS83S_[SSTV], RS90S_[SSDV], RS92S2_[SSDV], RS92S4_[SSDV], RS95S_[FM],
    /// RS95S_[SSTV], SilverSat_[SSDV], SO-125_[FM], SO-50_[FM], SONATE-2_[SSTV],
    /// SONATE-2_[VHF_Digi], T.Microsat-1_[Music], Ten-Koh2_[V/u], TO-108_[U/v], UO-11_[TLM]
    ///
    /// Only satellites in both FrequencyDatabase and AMSAT valid names are included.
    private static let amsatNameMapping: [String: String] = [
        // ISS — NORAD 25544
        "25544": "ISS_[FM]",
        
        // AO Series (AMSAT-OSCAR)
        "7530": "AO-7_[U/v]",       // Mode U/V; also available as AO-7_[V/a]
        "39444": "AO-73_[U/v]",
        "43017": "AO-91_[FM]",
        
        // SO Series (Saudi-OSCAR)
        "27607": "SO-50_[FM]",
        
        // FO Series (Fuji-OSCAR)
        "24278": "FO-29_[V/u]",
        
        // RS Series (Radio Sputnik)
        "44909": "RS-44_[V/u]",
        
        // JO Series (JordanSat-OSCAR)
        "43803": "JO-97_[U/v]",
        
        // IO Series
        "40931": "IO-86_[FM]",       // LAPAN-A2; also IO-86_[SSDV], IO-86_[VHF_Digi]
        
        // TO Series (Tsinghua-OSCAR)
        "44881": "TO-108_[U/v]",     // CAS-6
        
        // PO Series (Philippines-OSCAR)
        "43678": "PO-101_[FM]",      // DIWATA-2
        
        // QO Series (Qatar-OSCAR)
        "43700": "QO-100_[NB]",      // Es'hail-2 narrowband; also QO-100_[WB]
        
        // CAS-3H (LilacSat-2)
        "40908": "CAS-3H_[FM]",
    ]
}
