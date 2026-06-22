import type { PageLoad } from './$types';

export const load: PageLoad = async ({ parent, params }) => {
	const parentData = await parent();
	return {
		...parentData,
		params
	};
};
