import { createBrowserClient, createServerClient, isBrowser, parse } from '@supabase/ssr';
import { PUBLIC_SUPABASE_ANON_KEY, PUBLIC_SUPABASE_URL } from '$env/static/public';
import type { LayoutLoad } from './$types';

export const load: LayoutLoad = async ({ data, depends, fetch }) => {
	depends('supabase:auth');

	const supabase = isBrowser()
		? createBrowserClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
				global: { fetch }
			})
		: createServerClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
				global: { fetch },
				cookies: {
					getAll() {
						return data.cookies;
					}
				}
			});

	const {
		data: { session }
	} = await supabase.auth.getSession();

	let profile = null;
	if (session?.user) {
		const { data: profileData } = await supabase
			.from('profiles')
			.select('*')
			.eq('id', session.user.id)
			.single();
		profile = profileData;
	}

	const getCookie = (name: string) => {
		if (isBrowser()) {
			const cookie = parse(document.cookie);
			return cookie[name];
		}
		return data.cookies?.find((c) => c.name === name)?.value;
	};

	return { session, profile, supabase, getCookie };
};
